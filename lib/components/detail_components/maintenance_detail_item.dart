class MaintenanceDetailItem {
  final int id;

  final String? branchName;
  final String? branchAddress;

  final String? requesterName;
  final String? requesterPhone;

  final String title;
  final String? description;
  final String status;
  final String category;
  final String categoryName;

  final List<String> attachPhotoUrls;

  final String? vendorName;
  final String? vendorPhone;

  final String? estimateAmount;
  final String? estimateComment;
  final DateTime? workStartDate;
  final DateTime? workEndDate;

  final int estimateResubmitCount;

  final String? resultComment;
  final String? resultPhotoUrl;
  final DateTime? workCompletedAt;

  // ✅ 1차 승인(지점요청 승인: REQUESTED -> ESTIMATING)
  final String? requestApprovedByName;
  final DateTime? requestApprovedAt;

  // ✅ 2차 승인(견적 승인: APPROVAL_PENDING -> IN_PROGRESS)
  final String? estimateApprovedByName;
  final DateTime? estimateApprovedAt;

  // ✅ 1차 반려 사유 (REQUESTED -> HQ1_REJECTED)
  final String? requestRejectedReason;

  // ✅ 2차 반려 사유 (APPROVAL_PENDING -> HQ2_REJECTED)
  final String? estimateRejectedReason;

  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? vendorSubmittedAt;

  MaintenanceDetailItem({
    required this.id,
    this.branchName,
    this.branchAddress,
    this.requesterName,
    this.requesterPhone,
    required this.title,
    this.description,
    required this.status,
    required this.category,
    required this.categoryName,
    required this.attachPhotoUrls,
    this.vendorName,
    this.vendorPhone,
    this.estimateAmount,
    this.estimateComment,
    this.workStartDate,
    this.workEndDate,
    required this.estimateResubmitCount,
    this.resultComment,
    this.resultPhotoUrl,
    this.workCompletedAt,
    this.requestApprovedByName,
    this.requestApprovedAt,
    this.estimateApprovedByName,
    this.estimateApprovedAt,
    this.requestRejectedReason,
    this.estimateRejectedReason,
    this.createdAt,
    this.submittedAt,
    this.vendorSubmittedAt,
  });

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  static List<String> _urls(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  factory MaintenanceDetailItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetailItem(
      id: (json['id'] as num).toInt(),
      branchName: json['branchName'] as String?,
      branchAddress: json['branchAddress'] as String?,
      requesterName: json['requesterName'] as String?,
      requesterPhone: json['requesterPhone'] as String?,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      status: (json['status'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      attachPhotoUrls: _urls(json['attachPhotoUrls']),
      vendorName: json['vendorName'] as String?,
      vendorPhone: json['vendorPhone'] as String?,
      estimateAmount: json['estimateAmount']?.toString(),
      estimateComment: json['estimateComment'] as String?,
      workStartDate: _date(json['workStartDate']),
      workEndDate: _date(json['workEndDate']),
      estimateResubmitCount:
          (json['estimateResubmitCount'] as num?)?.toInt() ?? 0,
      resultComment: json['resultComment'] as String?,
      resultPhotoUrl: json['resultPhotoUrl'] as String?,
      workCompletedAt: _dt(json['workCompletedAt']),

      // ✅ 승인 1/2차
      requestApprovedByName: json['requestApprovedByName'] as String?,
      requestApprovedAt: _dt(json['requestApprovedAt']),
      estimateApprovedByName: json['estimateApprovedByName'] as String?,
      estimateApprovedAt: _dt(json['estimateApprovedAt']),

      // ✅ 반려 1/2차 (백엔드 DTO에서 내려줘야 함)
      requestRejectedReason: json['requestRejectedReason'] as String?,
      estimateRejectedReason: json['estimateRejectedReason'] as String?,

      createdAt: _dt(json['createdAt']),
      submittedAt: _dt(json['submittedAt']),
      vendorSubmittedAt: _dt(json['vendorSubmittedAt']),
    );
  }
}
