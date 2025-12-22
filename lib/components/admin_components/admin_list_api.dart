import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class HqRequestsApi {
  static Future<http.Response> fetchRequests({
    int page = 0,
    int size = 20,
    String? status, // e.g. "REQUESTED"
    String? category, // e.g. "HVAC"
    int? branchId,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'size': '$size',
      'sort': 'createdAt,desc',
    };
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (branchId != null) qp['branchId'] = '$branchId';

    final uri = Uri.parse(
      '$apiBase/hq/maintenance/requests',
    ).replace(queryParameters: qp);

    debugPrint('HQ LIST url=$uri');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('HQ LIST status=${res.statusCode}');
    // debugPrint('HQ LIST body=${res.body}'); // 길면 주석
    return res;
  }
}
