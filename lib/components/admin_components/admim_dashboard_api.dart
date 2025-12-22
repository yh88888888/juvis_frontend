import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class AdminDashboardApi {
  static Future<http.Response> fetchSummary() async {
    final uri = Uri.parse('$apiBase/api/hq/maintenances/summary');
    debugPrint('HQ SUMMARY url=$uri');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('HQ SUMMARY status=${res.statusCode}');
    debugPrint('HQ SUMMARY body=${res.body}');
    return res;
  }
}

class AdminSummary {
  final int requested;
  final int estimating;
  final int approvalPending;
  final int inProgress;
  final int completed;

  AdminSummary({
    required this.requested,
    required this.estimating,
    required this.approvalPending,
    required this.inProgress,
    required this.completed,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    int _i(String k) => (json[k] as num?)?.toInt() ?? 0;

    return AdminSummary(
      requested: _i('requested'),
      estimating: _i('estimating'),
      approvalPending: _i('approvalPending'),
      inProgress: _i('inProgress'),
      completed: _i('completed'),
    );
  }

  static AdminSummary fromBody(String body) =>
      AdminSummary.fromJson(jsonDecode(body) as Map<String, dynamic>);
}
