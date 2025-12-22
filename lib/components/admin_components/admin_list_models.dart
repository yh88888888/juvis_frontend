import 'dart:convert';

class Resp<T> {
  final int status;
  final String? msg;
  final T? body;

  const Resp({required this.status, required this.msg, required this.body});

  bool get ok => status == 200;

  /// 서버 응답 문자열(JSON) → Resp<dynamic>
  static Resp<dynamic> fromBody(String bodyStr) {
    final decoded = jsonDecode(bodyStr);
    if (decoded is! Map<String, dynamic>) {
      // 서버가 JSON Map이 아닌 경우 방어
      return Resp(status: 500, msg: 'Invalid response format', body: decoded);
    }
    return fromJson(decoded);
  }

  /// 서버 응답 Map → Resp<dynamic>
  static Resp<dynamic> fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as num?)?.toInt() ?? 500;
    final msg = json['msg']?.toString();
    final body = json['body']; // ✅ 핵심: 서버는 response가 아니라 body로 내려줌
    return Resp(status: status, msg: msg, body: body);
  }
}

class PageDTO<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int number; // current page
  final int size;

  PageDTO({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
  });

  static PageDTO<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawList = (json['content'] as List? ?? []);
    final list = rawList
        .whereType<Map>()
        .map((e) => itemFromJson(e.cast<String, dynamic>()))
        .toList();

    // ✅ Page 직렬화면 totalPages/totalElements/number/size 등이 있음
    // ✅ 혹시 없다면 안전하게 기본값
    return PageDTO<T>(
      content: list,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? list.length,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? list.length,
    );
  }
}

class HqRequestItem {
  final int id;
  final String? branchName;
  final String? requesterName;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? submittedAt;

  // ✅ 추가
  final String? estimateAmount;

  HqRequestItem({
    required this.id,
    required this.title,
    required this.status,
    this.branchName,
    this.requesterName,
    this.createdAt,
    this.submittedAt,
    this.estimateAmount,
  });

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  factory HqRequestItem.fromJson(Map<String, dynamic> json) {
    return HqRequestItem(
      id: (json['id'] as num).toInt(),
      branchName: json['branchName'] as String?,
      requesterName: json['requesterName'] as String?,
      title: (json['title'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      createdAt: _dt(json['createdAt']),
      submittedAt: _dt(json['submittedAt']),
      estimateAmount: json['estimateAmount']?.toString(), // ✅ 여기
    );
  }
}
