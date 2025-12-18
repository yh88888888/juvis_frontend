import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/components/photo_components/photo_models.dart';

import '../../config/api_config.dart';

class MaintenanceApi {
  static Future<http.Response> create(MaintenanceCreateDto dto) {
    return authRequest((accessToken) {
      return http.post(
        Uri.parse('$apiBase/api/branch/maintenances'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(dto.toJson()),
      );
    });
  }

  static Future<http.Response> submit(int id) {
    return authRequest((accessToken) {
      return http.post(
        Uri.parse('$apiBase/api/branch/maintenances/$id/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    });
  }
}
