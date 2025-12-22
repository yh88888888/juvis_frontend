import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/util/app_role.dart';
import 'package:juvis_faciliry/components/admin_components/admin_list_models.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_api.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_item.dart';

final maintenanceDetailProvider = FutureProvider.family
    .autoDispose<MaintenanceDetailItem, ({int id, AppRole role})>((
      ref,
      arg,
    ) async {
      final res = switch (arg.role) {
        AppRole.branch => await MaintenanceDetailApi.fetchBranchDetail(arg.id),
        AppRole.hq => await MaintenanceDetailApi.fetchHqDetail(arg.id),
        AppRole.vendor => await MaintenanceDetailApi.fetchVendorDetail(arg.id),
        _ => throw Exception('권한 확인 필요'),
      };

      if (res.statusCode != 200) {
        throw Exception('상세 조회 실패 (status=${res.statusCode})');
      }

      final wrapper = Resp.fromBody(res.body);

      // ✅ 서버 표준: status/msg/body (네가 쓰던 방식)
      if (!wrapper.ok || wrapper.body == null) {
        throw Exception('상세 wrapper fail: ${wrapper.msg ?? res.body}');
      }

      final body = wrapper.body;
      if (body is! Map<String, dynamic>) {
        throw Exception('상세 body 형식 오류: ${body.runtimeType}');
      }

      return MaintenanceDetailItem.fromJson(body);
    });
