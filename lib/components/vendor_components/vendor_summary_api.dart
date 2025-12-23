import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class VendorSummaryApi {
  static Future<http.Response> fetchSummary() async {
    final uri = Uri.parse('$apiBase/api/vendor/maintenances/summary');

    debugPrint("VENDOR SUMMARY url=$uri");

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint("VENDOR SUMMARY status=${res.statusCode}");
    debugPrint("VENDOR SUMMARY body=${res.body}");

    return res;
  }
}
