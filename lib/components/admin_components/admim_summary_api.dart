import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/_core/util/resp.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class AdminDashboardApi {
  static Future<http.Response> fetchSummary() async {
    final uri = Uri.parse('$apiBase/api/hq/maintenances/summary');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken, // ✅ 그대로
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }
}

class AdminSummary {
  final int requested;
  final int estimating;
  final int approvalPending;
  final int hq2Rejected;
  final int inProgress;
  final int completed;

  AdminSummary({
    required this.requested,
    required this.estimating,
    required this.approvalPending,
    required this.hq2Rejected,
    required this.inProgress,
    required this.completed,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    int _v(dynamic v) => (v as num?)?.toInt() ?? 0;

    return AdminSummary(
      requested: _v(json['requested']),
      estimating: _v(json['estimating']),
      approvalPending: _v(json['approvalPending'] ?? json['approval_pending']),
      hq2Rejected: _v(json['hq2Rejected'] ?? json['hq2_rejected']),
      inProgress: _v(json['inProgress'] ?? json['in_progress']),
      completed: _v(json['completed']),
    );
  }

  /// ✅ Resp 래핑 기준 파서 (방법2)
  static AdminSummary fromRespBody(String bodyStr) {
    final wrapper = Resp.fromBody(bodyStr);
    if (!wrapper.ok || wrapper.body == null || wrapper.body is! Map) {
      throw Exception('Invalid summary response: $bodyStr');
    }

    final map = Map<String, dynamic>.from(wrapper.body as Map);
    return AdminSummary.fromJson(map);
  }
}
