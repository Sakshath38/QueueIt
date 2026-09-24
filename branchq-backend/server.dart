import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ---------------- In-Memory Data Stores ----------------
final Map<String, Map<String, dynamic>> idempotencyStore = {};
final Map<String, Map<String, dynamic>> tokens = {};

final Map<String, int> slotCapacities = {
  'b1_Today_slot_1': 2,
  'b1_Today_slot_2': 0, // Contended / Conflict trigger
  'b1_Today_slot_3': 1,
  'b1_Today_slot_4': 4,
  'b2_Today_slot_1': 3,
  'b2_Today_slot_2': 1,
};

final List<Map<String, dynamic>> branches = [
  {
    'id': 'b1',
    'name': 'MG Road Central Branch',
    'address': '102 MG Road, Bangalore',
    'crowdLevel': 'Low',
    'distanceKm': 1.2,
    'services': [
      {
        'id': 's1',
        'name': 'Locker Operation',
        'estimatedMinutes': 15,
        'requiredDocuments': ['Locker Key', 'Original Photo ID'],
      },
      {
        'id': 's2',
        'name': 'Demand Draft / Pay Order',
        'estimatedMinutes': 10,
        'requiredDocuments': ['Cheque Leaf', 'Debit Account Details'],
      },
    ],
  },
  {
    'id': 'b2',
    'name': 'Indiranagar 100ft Branch',
    'address': 'Near 12th Main Junction, Indiranagar',
    'crowdLevel': 'High',
    'distanceKm': 3.8,
    'services': [
      {
        'id': 's3',
        'name': 'KYC & Re-KYC Update',
        'estimatedMinutes': 20,
        'requiredDocuments': [
          'Government ID',
          'Address Proof',
          'Passport Photo'
        ],
      },
      {
        'id': 's1',
        'name': 'Locker Operation',
        'estimatedMinutes': 15,
        'requiredDocuments': ['Locker Key', 'Original Photo ID'],
      },
    ],
  },
];

// ---------------- Helper Methods ----------------
void sendJson(HttpRequest req, int statusCode, Map<String, dynamic> data) {
  req.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..headers.add('Access-Control-Allow-Headers',
        'Origin, Content-Type, Accept, Authorization, Idempotency-Key')
    ..write(jsonEncode(data))
    ..close();
}

void sendBankError(
    HttpRequest req, int statusCode, String code, String message) {
  final traceId = 'tr_${Random().nextInt(999999)}';
  sendJson(req, statusCode, {
    'error': {
      'code': code,
      'message': message,
      'traceId': traceId,
    },
    'message': message,
    'traceId': traceId,
  });
}

// ---------------- Server Entrypoint ----------------
void main() async {
  // Use port from environment (e.g. Render / Cloud) or default to 8080
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 Pure Dart BranchQ Backend running on port $port');

  await for (HttpRequest req in server) {
    // Handle CORS preflight for web clients
    if (req.method == 'OPTIONS') {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        ..headers.add('Access-Control-Allow-Headers',
            'Origin, Content-Type, Accept, Authorization, Idempotency-Key')
        ..close();
      continue;
    }

    final path = req.uri.path;
    final segments = req.uri.pathSegments;

    // 1. GET /branches
    if (req.method == 'GET' && path == '/branches') {
      sendJson(req, 200, {'data': branches});
      continue;
    }

    // 2. GET /branches/:id
    if (req.method == 'GET' &&
        segments.length == 2 &&
        segments[0] == 'branches') {
      final id = segments[1];
      final match = branches.where((b) => b['id'] == id);
      if (match.isEmpty) {
        sendBankError(req, 404, 'BRANCH_NOT_FOUND', 'Branch not found.');
      } else {
        sendJson(req, 200, {'data': match.first});
      }
      continue;
    }

    // 3. GET /branches/:id/slots
    if (req.method == 'GET' &&
        segments.length == 3 &&
        segments[0] == 'branches' &&
        segments[2] == 'slots') {
      final branchId = segments[1];
      final date = req.uri.queryParameters['date'] ?? 'Today';

      final slotDefs = [
        {'id': 'slot_1', 'startTime': '10:00 AM'},
        {'id': 'slot_2', 'startTime': '10:30 AM'},
        {'id': 'slot_3', 'startTime': '11:00 AM'},
        {'id': 'slot_4', 'startTime': '11:30 AM'},
      ];

      final slots = slotDefs.map((s) {
        final key = '${branchId}_${date}_${s['id']}';
        return {
          'id': s['id'],
          'startTime': s['startTime'],
          'remainingCapacity': slotCapacities[key] ?? 0,
        };
      }).toList();

      sendJson(req, 200, {'data': slots});
      continue;
    }

    // 4. POST /appointments (Contention + Idempotency)
    if (req.method == 'POST' && path == '/appointments') {
      final idempotencyKey = req.headers.value('Idempotency-Key');
      final bodyStr = await utf8.decodeStream(req);
      final body =
          bodyStr.isNotEmpty ? jsonDecode(bodyStr) as Map<String, dynamic> : {};

      final branchId = body['branchId'] as String?;
      final slotId = body['slotId'] as String?;
      final serviceId = body['serviceId'] as String?;

      if (branchId == null || slotId == null || serviceId == null) {
        sendBankError(req, 422, 'VALIDATION_FAILED', 'Missing parameters.');
        continue;
      }

      // Check Idempotency Cache
      if (idempotencyKey != null &&
          idempotencyStore.containsKey(idempotencyKey)) {
        sendJson(req, 200, idempotencyStore[idempotencyKey]!);
        continue;
      }

      final capacityKey = '${branchId}_Today_$slotId';
      final currentCapacity = slotCapacities[capacityKey] ?? 0;

      // Slot Contention / Conflict check
      if (currentCapacity <= 0) {
        sendBankError(req, 409, 'SLOT_FULL',
            'This slot was just claimed by another user.');
        continue;
      }

      slotCapacities[capacityKey] = currentCapacity - 1;

      final tokenId = 'tok_${DateTime.now().millisecondsSinceEpoch}';
      final tokenRecord = {
        'id': tokenId,
        'tokenNumber': 'B-${10 + Random().nextInt(80)}',
        'position': 3,
        'estimatedWaitMinutes': 15,
        'counter': 'Counter 2',
        'status': 'WAITING',
      };

      tokens[tokenId] = tokenRecord;
      final responsePayload = {'data': tokenRecord};

      if (idempotencyKey != null) {
        idempotencyStore[idempotencyKey] = responsePayload;
      }

      sendJson(req, 201, responsePayload);
      continue;
    }

    // 5. GET /tokens/:id
    if (req.method == 'GET' &&
        segments.length == 2 &&
        segments[0] == 'tokens') {
      final tokenId = segments[1];
      final token = tokens[tokenId];

      if (token == null) {
        sendBankError(
            req, 404, 'TOKEN_NOT_FOUND', 'Active token expired or not found.');
        continue;
      }

      // Simulate movement forward in line
      int pos = token['position'] as int;
      if (pos > 1) {
        token['position'] = pos - 1;
        token['estimatedWaitMinutes'] = (pos - 1) * 5;
        token['status'] = (pos - 1 == 1) ? 'NEXT' : 'WAITING';
      } else if (pos == 1) {
        token['position'] = 0;
        token['estimatedWaitMinutes'] = 0;
        token['status'] = 'SERVING';
      }

      sendJson(req, 200, {'data': token});
      continue;
    }

    // Default 404
    sendBankError(req, 404, 'NOT_FOUND', 'Endpoint not found.');
  }
}
