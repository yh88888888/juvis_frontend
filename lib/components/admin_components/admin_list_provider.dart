import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/admin_components/admin_list_api.dart';
import 'package:juvis_faciliry/components/admin_components/admin_list_models.dart';

class HqListQuery {
  final int page;
  final int size;
  final String? status;
  final String? category;
  final int? branchId;

  const HqListQuery({
    this.page = 0,
    this.size = 20,
    this.status,
    this.category,
    this.branchId,
  });

  HqListQuery copyWith({
    int? page,
    int? size,
    String? status,
    String? category,
    int? branchId,
  }) {
    return HqListQuery(
      page: page ?? this.page,
      size: size ?? this.size,
      status: status ?? this.status,
      category: category ?? this.category,
      branchId: branchId ?? this.branchId,
    );
  }
}

final hqRequestListProvider =
    FutureProvider.family<PageDTO<HqRequestItem>, HqListQuery>((ref, q) async {
      final res = await HqRequestsApi.fetchRequests(
        page: q.page,
        size: q.size,
        status: q.status,
        category: q.category,
        branchId: q.branchId,
      );

      if (res.statusCode != 200) {
        throw Exception('HQ list fail: ${res.statusCode} ${res.body}');
      }

      // ✅ 서버 포맷: { status, msg, body }
      final wrapper = Resp.fromBody(res.body);

      if (!wrapper.ok || wrapper.body == null) {
        throw Exception('HQ list wrapper fail: ${wrapper.msg}');
      }

      return PageDTO.fromJson<HqRequestItem>(
        wrapper.body!, // ✅ content / totalPages ... 들어있는 body
        (m) => HqRequestItem.fromJson(m),
      );
    });
