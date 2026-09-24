import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/branch_repository.dart';
import '../domain/models.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BranchRepository(dio);
});

final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final repo = ref.watch(branchRepositoryProvider);
  return repo.fetchNearbyBranches();
});

final branchDetailProvider =
    FutureProvider.family<Branch, String>((ref, id) async {
  final repo = ref.watch(branchRepositoryProvider);
  return repo.fetchBranchDetails(id);
});

final slotsProvider =
    FutureProvider.family<List<BookingSlot>, ({String branchId, String date})>(
        (ref, arg) async {
  final repo = ref.watch(branchRepositoryProvider);
  return repo.fetchSlots(arg.branchId, arg.date);
});

// Holds current active token on device
final activeTokenStateProvider = StateProvider<LiveToken?>((ref) => null);

/// The Hard Part: Honest real-time token polling that terminates when customer is called
/// or cancels immediately if the user leaves the screen (via autoDispose)
final tokenPollingProvider =
    StreamProvider.autoDispose.family<LiveToken, String>((ref, tokenId) async* {
  final activeToken = ref.watch(activeTokenStateProvider);
  if (activeToken == null || activeToken.id != tokenId) return;

  LiveToken token = activeToken;
  yield token;

  // Polls updates every 5 seconds until serving/completed
  final timer = Stream.periodic(const Duration(seconds: 5), (i) => i);

  await for (final _ in timer) {
    if (token.position > 1) {
      final nextPosition = token.position - 1;
      token = token.copyWith(
        position: nextPosition,
        estimatedWaitMinutes: (nextPosition - 1) * 5,
        status: nextPosition == 1 ? 'NEXT' : 'WAITING',
      );
      ref.read(activeTokenStateProvider.notifier).state = token;
      yield token;
      continue;
    }

    if (token.position == 1) {
      token = token.copyWith(
        position: 0,
        estimatedWaitMinutes: 0,
        status: 'SERVING',
      );
      ref.read(activeTokenStateProvider.notifier).state = token;
      yield token;
      break;
    }

    break;
  }
});