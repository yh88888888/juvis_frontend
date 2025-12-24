import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class VendorSummaryApi {
  static Future<http.Response> fetchSummary() async {
    print('### fetchSummary CALLED ###');
    dev.log('### fetchSummary CALLED (log) ###');
    debugPrint('### fetchSummary CALLED (debugPrint) ###');

    final uri = Uri.parse('$apiBase/api/vendor/maintenances/summary');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });
    debugPrint('VENDOR SUMMARY status=${res.statusCode}');
    debugPrint('VENDOR SUMMARY raw=${res.body}');

    return res;
  }
}
