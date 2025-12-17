import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  static const _secure = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) async {
    await _secure.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secure.read(key: _accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secure.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secure.read(key: _refreshTokenKey);
  }

  static Future<void> clear() async {
    await _secure.deleteAll();
  }
}
