import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:branch_q/core/error/bank_error.dart';
import 'package:branch_q/features/branch/data/branch_repository.dart';

void main() {
  late BranchRepository repository;
  late Dio dio;

  setUp(() {
    dio = Dio();
    repository = BranchRepository(dio);
  });

  group('BranchRepository Unit Tests', () {
    test('fetchNearbyBranches returns populated branch list with services', () async {
      final branches = await repository.fetchNearbyBranches();

      expect(branches.isNotEmpty, true);
      expect(branches.first.name, contains('Branch'));
      expect(branches.first.services.isNotEmpty, true);
      expect(branches.first.services.first.requiredDocuments.isNotEmpty, true);
    });

    test('fetchSlots returns 15-minute slot intervals with positive capacity', () async {
      final slots = await repository.fetchSlots('b1', 'Today');

      expect(slots.length, 4);
      expect(slots.any((s) => s.remainingCapacity > 0), true);
      expect(slots.any((s) => s.isFull), true); // Verifies full slot flag
    });

    test('bookAppointment issues waiting token with positive wait time', () async {
      final token = await repository.bookAppointment(
        branchId: 'b1',
        slotId: 'slot_1',
        serviceId: 's1',
        idempotencyKey: 'test_key_123',
      );

      expect(token.status, 'WAITING');
      expect(token.position, greaterThan(0));
      expect(token.estimatedWaitMinutes, greaterThan(0));
      expect(token.tokenNumber.startsWith('B-'), true);
    });

    test('bookAppointment on a full slot throws ConflictError (HTTP 409)', () async {
      expect(
        () async => repository.bookAppointment(
          branchId: 'b1',
          slotId: 'slot_2', // Configured with 0 remaining capacity
          serviceId: 's1',
          idempotencyKey: 'test_key_conflict',
        ),
        throwsA(isA<ConflictError>()),
      );
    });
  });
}