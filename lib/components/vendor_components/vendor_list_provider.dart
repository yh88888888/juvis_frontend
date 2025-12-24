import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_lilst_model.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_list_api.dart';

class VendorListDTO {
  final List<VendorListItem> items;

  VendorListDTO({required this.items});

  factory VendorListDTO.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is List) {
      return VendorListDTO(
        items: raw
            .whereType<Map>()
            .map((e) => VendorListItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    return VendorListDTO(items: const []);
  }
}

final vendorListProvider = FutureProvider.autoDispose
    .family<VendorListDTO, String?>((ref, status) async {
      final res = await VendorListApi.fetchList(status: status);

      if (res.statusCode != 200) {
        throw Exception('vendor list fail: ${res.statusCode} ${res.body}');
      }

      final wrapper = Resp.fromBody(res.body);
      if (wrapper.ok != true || wrapper.body == null) {
        throw Exception('vendor list invalid wrapper: ${res.body}');
      }

      // 서버: Resp.ok(ListDTO) -> body: { items: [...] }
      final body = wrapper.body;
      if (body is Map) {
        return VendorListDTO.fromJson(Map<String, dynamic>.from(body as Map));
      }

      // 혹시 body가 문자열 JSON으로 한 번 더 감싸진 케이스 방어
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return VendorListDTO.fromJson(decoded);
        }
      }

      throw Exception('vendor list invalid body type: ${res.body}');
    });
