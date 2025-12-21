import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class MaintenanceDetailApi {
  static Future<http.Response> fetchBranchDetail(int id) async {
    final uri = Uri.parse('$apiBase/api/branch/maintenances/$id');

    // ✅ 1. 요청 전에 URL 확인
    debugPrint("DETAIL url=$uri");

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });

    // ✅ 2. 응답 확인
    debugPrint("DETAIL status=${res.statusCode}");
    debugPrint("DETAIL body=${res.body}");

    return res;
  }
}
