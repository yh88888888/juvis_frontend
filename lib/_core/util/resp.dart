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
