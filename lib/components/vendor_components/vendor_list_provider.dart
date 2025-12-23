import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_lilst_model.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_list_api.dart';

class VendorListQuery {
  final String? status;

  const VendorListQuery({this.status});

  VendorListQuery copyWith({String? status}) {
    return VendorListQuery(status: status ?? this.status);
  }
}

final vendorListProvider = FutureProvider.family
    .autoDispose<List<VendorListItem>, VendorListQuery>((ref, q) async {
      final res = await VendorListApi.fetchRequests(status: q.status);

      if (res.statusCode != 200) {
        throw Exception('VENDOR list fail: ${res.statusCode} ${res.body}');
      }

      final wrapper = Resp.fromBody(res.body);
      if (!wrapper.ok || wrapper.body == null) {
        throw Exception('VENDOR list wrapper fail: ${wrapper.msg}');
      }

      if (wrapper.body is! List) {
        throw Exception('VENDOR list invalid body: ${wrapper.body}');
      }

      final raw = (wrapper.body as List);
      final list = raw
          .whereType<Map>()
          .map((e) => VendorListItem.fromJson(e.cast<String, dynamic>()))
          .toList();

      // 최신순 정렬(서버가 정렬 안 해주면)
      list.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );

      return list;
    });
