import 'dart:math';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../domain/models.dart';
import '../../../core/network/error_mapper.dart';

class BranchRepository {
  final Dio _dio;
  static const _uuid = Uuid();

  BranchRepository(this._dio);

  // In-memory fallback dataset for offline/mock development
  static final List<Branch> _fallbackBranches = [
    const Branch(
      id: 'b1',
      name: 'MG Road Central Branch',
      address: '102 MG Road, Bangalore',
      crowdLevel: 'Low',
      distanceKm: 1.2,
      services: [
        BranchService(
          id: 's1',
          name: 'Locker Operation',
          estimatedMinutes: 15,
          requiredDocuments: ['Locker Key', 'Original Photo ID'],
        ),
        BranchService(
          id: 's2',
          name: 'Demand Draft / Pay Order',
          estimatedMinutes: 10,
          requiredDocuments: ['Cheque Leaf', 'Debit Account Details'],
        ),
      ],
    ),
    const Branch(
      id: 'b2',
      name: 'Indiranagar 100ft Branch',
      address: 'Near 12th Main Junction, Indiranagar',
      crowdLevel: 'High',
      distanceKm: 3.8,
      services: [
        BranchService(
          id: 's3',
          name: 'KYC & Re-KYC Update',
          estimatedMinutes: 20,
          requiredDocuments: ['Government ID', 'Address Proof', 'Passport Photo'],
        ),
        BranchService(
          id: 's1',
          name: 'Locker Operation',
          estimatedMinutes: 15,
          requiredDocuments: ['Locker Key', 'Original Photo ID'],
        ),
      ],
    ),
  ];

  static final Map<String, int> _fallbackSlotCapacity = {
    'slot_1': 2,
    'slot_2': 0, // Contended / Full
    'slot_3': 1,
    'slot_4': 4,
  };

  Future<List<Branch>> fetchNearbyBranches() async {
    try {
      final response = await _dio.get('/branches');
      final data = response.data['data'] as List;

      return data.map((json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        crowdLevel: json['crowdLevel'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        services: (json['services'] as List).map((s) => BranchService(
          id: s['id'] as String,
          name: s['name'] as String,
          estimatedMinutes: s['estimatedMinutes'] as int,
          requiredDocuments: List<String>.from(s['requiredDocuments'] ?? []),
        )).toList(),
      )).toList();
    } catch (e) {
      // Graceful fallback to course-aligned mock data if backend gateway is offline
      await Future.delayed(const Duration(milliseconds: 400));
      return _fallbackBranches;
    }
  }

  Future<Branch> fetchBranchDetails(String branchId) async {
    try {
      final response = await _dio.get('/branches/$branchId');
      final json = response.data['data'];

      return Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        crowdLevel: json['crowdLevel'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        services: (json['services'] as List).map((s) => BranchService(
          id: s['id'] as String,
          name: s['name'] as String,
          estimatedMinutes: s['estimatedMinutes'] as int,
          requiredDocuments: List<String>.from(s['requiredDocuments'] ?? []),
        )).toList(),
      );
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _fallbackBranches.firstWhere(
        (b) => b.id == branchId,
        orElse: () => throw ErrorMapper.map(e),
      );
    }
  }

  Future<List<BookingSlot>> fetchSlots(String branchId, String date) async {
    try {
      final response = await _dio.get(
        '/branches/$branchId/slots',
        queryParameters: {'date': date},
      );
      final list = response.data['data'] as List;

      return list.map((json) => BookingSlot(
        id: json['id'] as String,
        startTime: json['startTime'] as String,
        remainingCapacity: json['remainingCapacity'] as int,
      )).toList();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        BookingSlot(id: 'slot_1', startTime: '10:00 AM', remainingCapacity: _fallbackSlotCapacity['slot_1'] ?? 0),
        BookingSlot(id: 'slot_2', startTime: '10:30 AM', remainingCapacity: _fallbackSlotCapacity['slot_2'] ?? 0),
        BookingSlot(id: 'slot_3', startTime: '11:00 AM', remainingCapacity: _fallbackSlotCapacity['slot_3'] ?? 0),
        BookingSlot(id: 'slot_4', startTime: '11:30 AM', remainingCapacity: _fallbackSlotCapacity['slot_4'] ?? 0),
      ];
    }
  }

  // Idempotent appointment creation with header injection
  Future<LiveToken> bookAppointment({
    required String branchId,
    required String slotId,
    required String serviceId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();

    try {
      final response = await _dio.post(
        '/appointments',
        data: {
          'branchId': branchId,
          'slotId': slotId,
          'serviceId': serviceId,
        },
        options: Options(
          headers: {
            'Idempotency-Key': key,
          },
        ),
      );

      final json = response.data['data'];
      return LiveToken(
        id: json['id'] as String,
        tokenNumber: json['tokenNumber'] as String,
        position: json['position'] as int,
        estimatedWaitMinutes: json['estimatedWaitMinutes'] as int,
        counter: json['counter'] as String,
        status: json['status'] as String,
      );
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      final capacity = _fallbackSlotCapacity[slotId] ?? 0;
      if (capacity <= 0) {
        throw ErrorMapper.map(
          DioException(
            requestOptions: RequestOptions(path: '/appointments'),
            response: Response(
              requestOptions: RequestOptions(path: '/appointments'),
              statusCode: 409,
              data: {'message': 'This slot was just claimed by another user.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      }

      _fallbackSlotCapacity[slotId] = capacity - 1;

      return LiveToken(
        id: 'tok_${Random().nextInt(90000) + 10000}',
        tokenNumber: 'B-${Random().nextInt(80) + 10}',
        position: 3,
        estimatedWaitMinutes: 15,
        counter: 'Counter 2',
        status: 'WAITING',
      );
    }
  }
}