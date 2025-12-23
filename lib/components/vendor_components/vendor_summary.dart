class VendorSummary {
  final int estimating; // 견적 제출 필요
  final int approvalPending; // 본사 승인 대기
  final int inProgress; // 작업 중 (결과 제출 필요)
  final int completed; // 작업 완료

  VendorSummary({
    required this.estimating,
    required this.approvalPending,
    required this.inProgress,
    required this.completed,
  });

  factory VendorSummary.fromJson(Map<String, dynamic> json) {
    return VendorSummary(
      estimating: (json['estimating'] as num?)?.toInt() ?? 0,
      approvalPending: (json['approvalPending'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }
}
