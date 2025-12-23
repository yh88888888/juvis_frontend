import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class NotificationApi {
  static Future<http.Response> fetchUnreadCount() async {
    final uri = Uri.parse('$apiBase/api/notifications/unread-count');
    debugPrint('NOTIF COUNT url=$uri');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('NOTIF COUNT status=${res.statusCode}');
    debugPrint('NOTIF COUNT body=${res.body}');
    return res;
  }

  static Future<http.Response> fetchList() async {
    final uri = Uri.parse('$apiBase/api/notifications');
    debugPrint('NOTIF LIST url=$uri');

    final res = await authRequest((accessToken) {
      return http.get(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('NOTIF LIST status=${res.statusCode}');
    debugPrint('NOTIF LIST body=${res.body}');
    return res;
  }

  static Future<http.Response> markRead(int id) async {
    final uri = Uri.parse('$apiBase/api/notifications/$id/read');
    debugPrint('NOTIF READ url=$uri');

    final res = await authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('NOTIF READ status=${res.statusCode}');
    debugPrint('NOTIF READ body=${res.body}');
    return res;
  }

  static Future<http.Response> markAllRead() async {
    final uri = Uri.parse('$apiBase/api/notifications/read-all');
    debugPrint('NOTIF READ ALL url=$uri');

    final res = await authRequest((accessToken) {
      return http.post(
        uri,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );
    });

    debugPrint('NOTIF READ ALL status=${res.statusCode}');
    debugPrint('NOTIF READ ALL body=${res.body}');
    return res;
  }
}
