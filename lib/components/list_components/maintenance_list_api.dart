import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../_core/util/auth_request.dart';
import '../../config/api_config.dart';

class MaintenanceListApi {
  static Future<http.Response> fetchBranchList({
    int page = 0,
    int size = 20,
    String? status,
    String? category,
  }) {
    final qp = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (category != null && category.isNotEmpty) qp['category'] = category;

    final uri = Uri.parse(
      '$apiBase/api/branch/maintenances',
    ).replace(queryParameters: qp);

    return authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });
  }

  static List<dynamic> extractPageContent(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final respBody = (map['body'] ?? map) as Map<String, dynamic>;
    final page = (respBody['content'] ?? respBody) as dynamic;

    if (page is List) return page;
    // 혹시 서버가 body에 바로 list만 주는 형태로 바뀌어도 안전하게
    return const [];
  }
}
