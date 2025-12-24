import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class NotificationApi {
  static Future<http.Response> fetchUnreadCount() async {
    final uri = Uri.parse('$apiBase/api/notifications/unread-count');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }

  static Future<http.Response> fetchList() async {
    final uri = Uri.parse('$apiBase/api/notifications');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }

  static Future<http.Response> markRead(int id) async {
    final uri = Uri.parse('$apiBase/api/notifications/$id/read');

    final res = await authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }

  static Future<http.Response> markAllRead() async {
    final uri = Uri.parse('$apiBase/api/notifications/read-all');

    final res = await authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    return res;
  }
}
