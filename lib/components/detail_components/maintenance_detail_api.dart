import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class MaintenanceDetailApi {
  // ----------------------------
  // GET: 상세 조회
  // ----------------------------
  static Future<http.Response> fetchBranchDetail(int id) async {
    final uri = Uri.parse('$apiBase/api/branch/maintenances/$id');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }

  static Future<http.Response> fetchHqDetail(int id) async {
    final uri = Uri.parse('$apiBase/api/hq/maintenance/requests/$id');
    return authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  static Future<http.Response> fetchVendorDetail(int id) async {
    final uri = Uri.parse('$apiBase/api/vendor/maintenances/$id');
    return authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  // ----------------------------
  // ✅ HQ: 1차 승인 (REQUESTED -> ESTIMATING)
  // ----------------------------
  static Future<http.Response> hqApproveRequest({required int id}) async {
    final uri = Uri.parse(
      '$apiBase/api/hq/maintenance/requests/$id/approve-request',
    );

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
    });
  }

  // ----------------------------
  // ✅ HQ: 2차 승인 (APPROVAL_PENDING -> IN_PROGRESS)
  // ----------------------------
  static Future<http.Response> hqApproveEstimate({required int id}) async {
    final uri = Uri.parse(
      '$apiBase/api/hq/maintenance/requests/$id/approve-estimate',
    );

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
    });
  }

  // ----------------------------
  // ✅ HQ: 1차 반려 (REQUESTED -> HQ1_REJECTED)
  // ----------------------------
  static Future<http.Response> hqRejectRequest({
    required int id,
    required String reason,
  }) async {
    final uri = Uri.parse(
      '$apiBase/api/hq/maintenance/requests/$id/reject-request',
    );

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );
    });
  }

  // ----------------------------
  // ✅ HQ: 2차 반려 (APPROVAL_PENDING -> HQ2_REJECTED)
  // ----------------------------
  static Future<http.Response> hqRejectEstimate({
    required int id,
    required String reason,
  }) async {
    final uri = Uri.parse(
      '$apiBase/api/hq/maintenance/requests/$id/reject-estimate',
    );

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );
    });
  }

  // ----------------------------
  // Vendor: 견적 제출
  // ----------------------------
  static Future<http.Response> submitEstimate({
    required int id,
    required String estimateAmount,
    String? estimateComment,
    DateTime? workStartDate,
    DateTime? workEndDate,
  }) async {
    final uri = Uri.parse(
      '$apiBase/api/vendor/maintenance/requests/$id/estimate',
    );

    String? fmtDate(DateTime? d) {
      if (d == null) return null;
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    final body = jsonEncode({
      "estimateAmount": estimateAmount,
      "estimateComment": estimateComment,
      "workStartDate": fmtDate(workStartDate),
      "workEndDate": fmtDate(workEndDate),
    });

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    });
  }

  // ----------------------------
  // Vendor: 작업 완료 제출
  // ----------------------------
  static Future<http.Response> completeWork({
    required int id,
    required String resultComment,
    String? resultPhotoUrl,
    DateTime? actualEndDate,
  }) async {
    final uri = Uri.parse(
      '$apiBase/api/vendor/maintenance/requests/$id/complete',
    );

    String? fmtDate(DateTime? d) {
      if (d == null) return null;
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    final body = jsonEncode({
      "resultComment": resultComment,
      "resultPhotoUrl": resultPhotoUrl,
      "actualEndDate": fmtDate(actualEndDate),
    });

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    });
  }

  // ----------------------------
  // Branch: 재제출
  // ----------------------------
  static Future<http.Response> branchResubmit({required int id}) async {
    final uri = Uri.parse('$apiBase/api/branch/maintenances/$id/submit');

    return authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': '$accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
    });
  }
}
