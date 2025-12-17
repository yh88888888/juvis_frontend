class HqSummary {
  final int pendingCount;
  final int unreadCount;
  final int todayDraftCount;
  final int completedCount;

  HqSummary({
    required this.pendingCount,
    required this.unreadCount,
    required this.todayDraftCount,
    required this.completedCount,
  });

  factory HqSummary.fromJson(Map<String, dynamic> json) {
    return HqSummary(
      pendingCount: json['pendingCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      todayDraftCount: json['todayDraftCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
    );
  }
}
