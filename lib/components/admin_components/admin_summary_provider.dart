import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/admin_components/admim_dashboard_api.dart';

final adminSummaryProvider = FutureProvider<AdminSummary>((ref) async {
  final res = await AdminDashboardApi.fetchSummary();
  if (res.statusCode != 200) {
    throw Exception('summary fail: ${res.statusCode} ${res.body}');
  }
  return AdminSummary.fromBody(res.body);
});
