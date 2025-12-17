import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';

import '../../config/api_config.dart';
import 'maintenance_category.dart';

class MaintenancePhotoDto {
  final String fileKey;
  final String url;

  MaintenancePhotoDto({required this.fileKey, required this.url});

  Map<String, dynamic> toJson() => {'fileKey': fileKey, 'url': url};
}

class MaintenanceCreateDto {
  final String title;
  final String description;
  final MaintenanceCategory category;
  final bool submit; // 저장: false, 제출용 생성: true (우리는 저장은 false만 쓸 것)
  final List<MaintenancePhotoDto> photos;

  MaintenanceCreateDto({
    required this.title,
    required this.description,
    required this.category,
    required this.submit,
    required this.photos,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category.toJson,
    'submit': submit,
    'photos': photos.map((p) => p.toJson()).toList(),
  };
}

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
