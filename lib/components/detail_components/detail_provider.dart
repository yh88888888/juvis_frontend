import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_api.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_item.dart';

final maintenanceDetailProvider =
    FutureProvider.family<MaintenanceDetailItem, int>((ref, id) async {
      final res = await MaintenanceDetailApi.fetchBranchDetail(id);

      if (res.statusCode != 200) {
        throw Exception('상세 조회 실패 (status=${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final body = decoded['body'] as Map<String, dynamic>; // Resp.ok 구조
      return MaintenanceDetailItem.fromJson(body);
    });
