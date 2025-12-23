import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/util/resp.dart';
import 'package:juvis_faciliry/components/admin_components/admim_summary_api.dart';

// ✅ 관리자 대시보드 요약 Provider
// - autoDispose: 화면 벗어나거나 로그아웃 시 캐시 제거
// - invalidate 시 즉시 재호출
final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((
  ref,
) async {
  // (선택) 너무 잦은 dispose 방지하고 싶으면 잠깐 유지 가능
  // ref.keepAlive(const Duration(seconds: 5));

  final res = await AdminDashboardApi.fetchSummary();

  if (res.statusCode != 200) {
    throw Exception('summary fail: ${res.statusCode} ${res.body}');
  }

  final wrapper = Resp.fromBody(res.body);

  if (!wrapper.ok || wrapper.body == null || wrapper.body is! Map) {
    throw Exception('summary invalid body: ${res.body}');
  }

  final map = Map<String, dynamic>.from(wrapper.body as Map);

  return AdminSummary.fromJson(map);
});
