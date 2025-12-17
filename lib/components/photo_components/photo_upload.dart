import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';

import '../../config/api_config.dart';

class PresignReq {
  final String fileName;
  final String contentType;

  PresignReq({required this.fileName, required this.contentType});

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'contentType': contentType,
  };
}

class PresignRes {
  final String uploadUrl;
  final String fileKey;
  final String? publicUrl;

  PresignRes({required this.uploadUrl, required this.fileKey, this.publicUrl});

  factory PresignRes.fromJson(Map<String, dynamic> json) {
    final uploadUrl = json['uploadUrl'];
    final fileKey = json['fileKey'];
    final publicUrl = json['publicUrl'];

    if (uploadUrl == null || fileKey == null) {
      throw Exception(
        'presign 응답 필드 누락: uploadUrl=$uploadUrl, fileKey=$fileKey / json=$json',
      );
    }

    return PresignRes(
      uploadUrl: uploadUrl as String,
      fileKey: fileKey as String,
      publicUrl: publicUrl as String?, // ✅ 없으면 null
    );
  }
}

class UploadApi {
  static String buildPublicUrl(String fileKey) {
    // presign uploadUrl에 이미 bucket/region이 있으니, 그걸로 만드는 게 제일 안전
    // (여기서는 로그 기준 bucket/region 고정 버전)
    return 'https://juvis-upload-dev.s3.ap-northeast-2.amazonaws.com/$fileKey';
  }

  /// 1) presign 발급
  static Future<PresignRes> presign({
    required String fileName,
    required String contentType,
  }) async {
    final res = await authRequest((accessToken) {
      return http.post(
        Uri.parse('$apiBase/api/uploads/presign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          PresignReq(fileName: fileName, contentType: contentType).toJson(),
        ),
      );
    });

    if (res.statusCode != 200) {
      throw Exception('presign 실패 (status: ${res.statusCode})');
    }
    debugPrint('presign raw=${res.body}');

    final map = jsonDecode(res.body);
    debugPrint('presign decoded=$map');

    // 네 Resp wrapper면 map['body']로 바꿔야 함
    // 케이스1) { body: { uploadUrl... } }
    dynamic body = map['body'] ?? map;

    // 케이스2) { body: { data: { uploadUrl... } } }
    if (body is Map && body['data'] != null) body = body['data'];

    // 케이스3) { response: { uploadUrl... } }
    if (body is Map && body['response'] != null) body = body['response'];

    return PresignRes.fromJson(body as Map<String, dynamic>);
  }

  static Future<void> putToS3Bytes({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    debugPrint('S3 PUT status=${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      debugPrint('S3 PUT body=${res.body}');
      throw Exception('S3 업로드 실패 (status: ${res.statusCode})');
    }
  }

  /// 2) S3 PUT 업로드 (presigned URL은 Authorization 헤더 넣으면 안되는 경우 많음)
  static Future<void> putToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        // 🔴 테스트 중에는 Content-Type 제거 권장
        // 'Content-Type': contentType,
      },
      body: bytes,
    );

    debugPrint('S3 PUT status=${res.statusCode}');
    debugPrint('S3 PUT headers=${res.headers}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      debugPrint('S3 PUT body=${res.body}');
      throw Exception('S3 업로드 실패 (status: ${res.statusCode})');
    }
  }

  /// 3) maintenance에 사진 메타 등록
  static Future<void> attachPhoto({
    required int maintenanceId,
    required String fileKey,
    required String url,
  }) async {
    final res = await authRequest((accessToken) {
      return http.post(
        Uri.parse('$apiBase/api/maintenance/$maintenanceId/photos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fileKey': fileKey, 'url': url}),
      );
    });

    if (res.statusCode != 200) {
      throw Exception('사진 메타 저장 실패 (status: ${res.statusCode})');
    }
  }
}
