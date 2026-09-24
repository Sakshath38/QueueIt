class Branch {
  final String id;
  final String name;
  final String address;
  final String crowdLevel; // Low, Moderate, High
  final double distanceKm;
  final List<BranchService> services;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.crowdLevel,
    required this.distanceKm,
    required this.services,
  });
}

class BranchService {
  final String id;
  final String name;
  final int estimatedMinutes;
  final List<String> requiredDocuments;

  const BranchService({
    required this.id,
    required this.name,
    required this.estimatedMinutes,
    required this.requiredDocuments,
  });
}

class BookingSlot {
  final String id;
  final String startTime; // e.g., "10:15 AM"
  final int remainingCapacity;

  const BookingSlot({
    required this.id,
    required this.startTime,
    required this.remainingCapacity,
  });

  bool get isFull => remainingCapacity <= 0;
}

class LiveToken {
  final String id;
  final String tokenNumber;
  final int position;
  final int estimatedWaitMinutes;
  final String counter;
  final String status; // WAITING, NEXT, SERVING

  const LiveToken({
    required this.id,
    required this.tokenNumber,
    required this.position,
    required this.estimatedWaitMinutes,
    required this.counter,
    required this.status,
  });

  LiveToken copyWith({
    int? position,
    int? estimatedWaitMinutes,
    String? status,
  }) {
    return LiveToken(
      id: id,
      tokenNumber: tokenNumber,
      position: position ?? this.position,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      counter: counter,
      status: status ?? this.status,
    );
  }
}