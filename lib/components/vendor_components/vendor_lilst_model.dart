import 'dart:convert';

class Resp<T> {
  final int status;
  final String? msg;
  final T? body;

  const Resp({required this.status, required this.msg, required this.body});

  bool get ok => status == 200;

  static Resp<dynamic> fromBody(String bodyStr) {
    final decoded = jsonDecode(bodyStr);
    if (decoded is! Map<String, dynamic>) {
      return Resp(status: 500, msg: 'Invalid response format', body: decoded);
    }
    final status = (decoded['status'] as num?)?.toInt() ?? 500;
    final msg = decoded['msg']?.toString();
    final body = decoded['body'];
    return Resp(status: status, msg: msg, body: body);
  }
}

/// ✅ 서버 MaintenanceResponse.SimpleDTO 대응(필드가 달라도 안전하게)
class VendorListItem {
  final int id;
  final String title;
  final String status;

  final String? category;
  final String? branchName;
  final DateTime? createdAt;
  final DateTime? submittedAt;

  // 필요하면 더 추가 가능 (estimateAmount 등)
  final String? estimateAmount;

  VendorListItem({
    required this.id,
    required this.title,
    required this.status,
    this.category,
    this.branchName,
    this.createdAt,
    this.submittedAt,
    this.estimateAmount,
  });

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory VendorListItem.fromJson(Map<String, dynamic> json) {
    return VendorListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      category: json['category']?.toString(),
      branchName: json['branchName']?.toString(),
      createdAt: _dt(json['createdAt']),
      submittedAt: _dt(json['submittedAt']),
      estimateAmount: json['estimateAmount']?.toString(),
    );
  }
}
