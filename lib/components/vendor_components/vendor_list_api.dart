import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class VendorListApi {
  static Future<http.Response> fetchList({String? status}) async {
    final uri = Uri.parse('$apiBase/api/vendor/maintenances').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    return authRequest((accessToken) {
      // accessToken에 Bearer가 이미 포함되어 내려오는 구조라면 그대로 사용
      // (너 로그인 raw에서 accessToken이 "Bearer ..."였음)
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });
  }
}
