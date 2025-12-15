import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../_core/util/auth_request.dart';
import '../_core/util/token_storage.dart';
import '../config/api_config.dart';
import 'session_user.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionUser?>(
  (ref) => SessionNotifier(ref),
);

class SessionNotifier extends StateNotifier<SessionUser?> {
  final Ref ref;

  SessionNotifier(this.ref) : super(null);

  /// 앱 시작 시 자동 세션 초기화: 토큰 있으면 /api/me로 사용자 로드
  Future<void> initSession() async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    // 둘 다 없으면 로그인 상태 아님
    if (accessToken == null && refreshToken == null) {
      state = null;
      return;
    }

    try {
      final res = await authRequest((token) {
        return http.get(
          Uri.parse('$apiBase/api/me'),
          headers: {'Authorization': token, 'Content-Type': 'application/json'},
        );
      });

      if (res.statusCode != 200) {
        await logout();
        return;
      }

      final decoded = jsonDecode(res.body);
      final body = decoded['body'];

      state = SessionUser(
        id: body['userId'] ?? body['id'],
        // 서버 응답 키 차이 대비
        username: body['username'],
        name: body['name'],
        role: body['role'],
        jwt: accessToken ?? '', // (권장) SessionUser에서 jwt 필드 제거 가능
      );
    } catch (_) {
      await logout();
    }
  }

  /// 로그인: 토큰 저장 + state 세팅
  /// (UI에서는 await login(...) 후 화면 이동)
  Future<SessionUser> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse("$apiBase/api/auth/login");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    // HTTP 레벨 에러
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("서버 오류: ${res.statusCode}");
    }

    final decoded = jsonDecode(res.body);

    // Resp<T> 규격(status/msg/body) 기준
    if (decoded["status"] != 200) {
      final msg = decoded["msg"] ?? "알 수 없는 오류";
      throw Exception("요청 실패: $msg");
    }

    final body = decoded["body"] as Map<String, dynamic>;

    // ✅ 서버가 accessToken/refreshToken을 준다는 가정
    final accessToken = body["accessToken"] as String?;
    final refreshToken = body["refreshToken"] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception("토큰이 응답에 없습니다. (accessToken/refreshToken 확인 필요)");
    }

    // ✅ 토큰 저장
    await TokenStorage.saveAccessToken(accessToken);
    await TokenStorage.saveRefreshToken(refreshToken);

    // ✅ state 세팅
    final user = SessionUser(
      id: body["id"] ?? body["userId"],
      // 서버 키 차이 대비
      username: body["username"],
      name: body["name"],
      role: body["role"],
      jwt: accessToken, // (권장) SessionUser.jwt 제거 가능. 임시로 accessToken 넣음
    );

    state = user;
    return user;
  }

  /// state 직접 세팅이 필요할 때(특수 케이스)
  void setUser(SessionUser user) {
    state = user;
  }

  /// 로그아웃: SecureStorage + state 정리
  Future<void> logout() async {
    state = null;
    await TokenStorage.clear();
  }
}
