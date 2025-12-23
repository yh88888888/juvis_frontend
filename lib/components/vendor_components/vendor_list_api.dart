import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class VendorListApi {
  /// GET /api/vendor/maintenance/requests?status=...
  static Future<http.Response> fetchRequests({String? status}) async {
    final base = '$apiBase/api/vendor/maintenance/requests';
    final uri = (status == null || status.isEmpty)
        ? Uri.parse(base)
        : Uri.parse('$base?status=$status');

    debugPrint("VENDOR LIST url=$uri");

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint("VENDOR LIST status=${res.statusCode}");
    debugPrint("VENDOR LIST body=${res.body}");

    return res;
  }
}
