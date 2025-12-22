import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/_core/util/token_storage.dart';
import 'package:juvis_faciliry/config/api_config.dart';

import 'session_user.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionUser?>(
  (ref) => SessionNotifier(ref),
);

class SessionNotifier extends StateNotifier<SessionUser?> {
  final Ref ref;

  SessionNotifier(this.ref) : super(null);

  /// 앱 시작 시 자동 세션 초기화 (/api/me)
  Future<void> initSession() async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

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

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final body = decoded['body'] as Map<String, dynamic>;

      final latestAccessToken = await TokenStorage.getAccessToken() ?? '';

      state = SessionUser(
        id: body['id'] ?? body['userId'],
        username: (body['username'] ?? '') as String,
        name: body['name'] as String?,
        // ✅ HQ null 허용
        role: (body['role'] ?? 'HQ') as String,
        jwt: latestAccessToken,
      );
    } catch (_) {
      await logout();
    }
  }

  /// 로그인
  Future<SessionUser> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$apiBase/api/auth/login');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('서버 오류: ${res.statusCode}');
    }

    // 🔎 디버그 로그 (개발 중 유지)
    // ignore: avoid_print
    print('LOGIN status=${res.statusCode}');
    // ignore: avoid_print
    print('LOGIN raw=${res.body}');

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (decoded['status'] != 200) {
      throw Exception(decoded['msg'] ?? '로그인 실패');
    }

    final body = decoded['body'] as Map<String, dynamic>;

    final accessToken = body['accessToken'] as String?;
    final refreshToken = body['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('토큰이 응답에 없습니다.');
    }

    final user = SessionUser(
      id: body['id'] as int,
      username: (body['username'] ?? '') as String,
      name: body['name'] as String?,
      // ✅ null 허용
      role: (body['role'] ?? 'HQ') as String,
      jwt: accessToken,
    );

    await TokenStorage.saveAccessToken(accessToken);
    await TokenStorage.saveRefreshToken(refreshToken);

    state = user;
    return user;
  }

  void setUser(SessionUser user) {
    state = user;
  }

  Future<void> logout() async {
    state = null;
    await TokenStorage.clear();
  }
}
