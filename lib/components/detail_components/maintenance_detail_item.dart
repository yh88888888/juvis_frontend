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

  final String? resultComment;
  final String? resultPhotoUrl;
  final DateTime? workCompletedAt;

  final String? approvedByName;
  final DateTime? approvedAt;

  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? vendorSubmittedAt;
  final String? rejectedReason;

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
    this.resultComment,
    this.resultPhotoUrl,
    this.workCompletedAt,
    this.approvedByName,
    this.approvedAt,
    this.createdAt,
    this.submittedAt,
    this.vendorSubmittedAt,
    this.rejectedReason,
  });

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  static List<String> _urls(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.whereType<String>().toList();
    }
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

      // ✅ 여기서 받아오기 (백엔드 JSON 키도 이 이름으로 맞추는 걸 추천)
      attachPhotoUrls: _urls(json['attachPhotoUrls']),

      vendorName: json['vendorName'] as String?,
      vendorPhone: json['vendorPhone'] as String?,
      estimateAmount: json['estimateAmount']?.toString(),
      estimateComment: json['estimateComment'] as String?,
      workStartDate: _date(json['workStartDate']),
      workEndDate: _date(json['workEndDate']),
      resultComment: json['resultComment'] as String?,
      resultPhotoUrl: json['resultPhotoUrl'] as String?,
      workCompletedAt: _dt(json['workCompletedAt']),
      approvedByName: json['approvedByName'] as String?,
      approvedAt: _dt(json['approvedAt']),
      createdAt: _dt(json['createdAt']),
      submittedAt: _dt(json['submittedAt']),
      vendorSubmittedAt: _dt(json['vendorSubmittedAt']),
      rejectedReason: json['rejectedReason'] as String?,
    );
  }
}
