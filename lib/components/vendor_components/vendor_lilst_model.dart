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
  final String status; // enum 문자열
  final String? branchName;
  final String? requesterName;
  final DateTime createdAt;

  VendorListItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.branchName,
    this.requesterName,
  });

  factory VendorListItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is String)
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return VendorListItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      branchName: json['branchName'] as String?,
      requesterName: json['requesterName'] as String?,
      createdAt: parseDt(json['createdAt']),
    );
  }
}
