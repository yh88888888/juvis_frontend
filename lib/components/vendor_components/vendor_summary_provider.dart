import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_summary.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_summary_api.dart';

import '../admin_components/admin_list_models.dart';

final vendorSummaryProvider = FutureProvider.autoDispose<VendorSummary>((
  ref,
) async {
  final res = await VendorSummaryApi.fetchSummary();

  if (res.statusCode != 200) {
    throw Exception('summary fail: ${res.statusCode} ${res.body}');
  }

  final resp = Resp.fromBody(res.body);
  if (!resp.ok || resp.body == null || resp.body is! Map<String, dynamic>) {
    throw Exception('summary invalid body: ${res.body}');
  }

  return VendorSummary.fromJson(resp.body as Map<String, dynamic>);
});
