import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/list_components/maintenance_list_api.dart';
import 'package:juvis_faciliry/components/list_components/maintenance_list_item.dart';

final maintenanceListProvider = FutureProvider<List<MaintenanceListItem>>((
  ref,
) async {
  final res = await MaintenanceListApi.fetchBranchList(page: 0, size: 20);
  if (res.statusCode != 200) {
    throw Exception('목록 조회 실패: ${res.statusCode} ${res.body}');
  }

  final listJson = MaintenanceListApi.extractPageContent(res.body);
  return listJson
      .map((e) => MaintenanceListItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
