import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../util/token_storage.dart';

Future<http.Response> authRequest(
  Future<http.Response> Function(String accessToken) requestFn,
) async {
  final accessToken = await TokenStorage.getAccessToken();
  if (accessToken == null) {
    throw Exception('로그인 필요');
  }

  try {
    // 1️⃣ 최초 요청 (timeout 필수)
    final response = await requestFn(
      accessToken,
    ).timeout(const Duration(seconds: 5));

    // 정상 응답
    if (response.statusCode != 401) {
      return response;
    }

    // 2️⃣ accessToken 만료 → refresh 시도 (딱 1번)
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      await TokenStorage.clear();
      throw Exception('세션 만료');
    }

    final refreshRes = await http
        .post(
          Uri.parse('$apiBase/api/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 5));

    if (refreshRes.statusCode != 200) {
      await TokenStorage.clear();
      throw Exception('세션 만료');
    }

    final decoded = jsonDecode(refreshRes.body);
    final newAccessToken = decoded['body']?['accessToken'];

    if (newAccessToken == null) {
      await TokenStorage.clear();
      throw Exception('세션 만료');
    }

    // 3️⃣ 새 토큰 저장
    await TokenStorage.saveAccessToken(newAccessToken);

    // 4️⃣ 원래 요청 1회 재시도 (여기서 또 401이면 그냥 반환)
    return await requestFn(newAccessToken).timeout(const Duration(seconds: 5));
  } catch (e) {
    // 🔥 여기서 무조건 종료 보장
    await TokenStorage.clear();
    rethrow;
  }
}
