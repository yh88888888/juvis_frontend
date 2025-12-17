import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class MaintenanceDetailItem {
  final int id;
  final String title;
  final String status;
  final String? description;
  final String? branchName;
  final String? requesterName;
  final DateTime? createdAt;
  final DateTime? submittedAt;

  MaintenanceDetailItem({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.branchName,
    required this.requesterName,
    required this.createdAt,
    required this.submittedAt,
  });

  factory MaintenanceDetailItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetailItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      branchName: json['branchName'] as String?,
      requesterName: json['requesterName'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt']),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt']),
    );
  }
}

class MaintenanceDetailPage extends StatefulWidget {
  final int id;
  const MaintenanceDetailPage({super.key, required this.id});

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  bool _loading = true;
  String? _error;
  MaintenanceDetailItem? _item;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$apiBase/api/branch/maintenances/${widget.id}');

      final res = await authRequest((token) {
        return http.get(
          uri,
          headers: {'Authorization': token, 'Content-Type': 'application/json'},
        );
      });

      if (res.statusCode != 200) {
        throw Exception('서버 오류: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final body = decoded['body'] as Map<String, dynamic>;

      setState(() {
        _item = MaintenanceDetailItem.fromJson(body);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '상세를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '미정';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('상세')),
        body: Center(child: Text(_error!)),
      );
    }

    final item = _item!;
    return Scaffold(
      appBar: AppBar(title: Text('문서번호 ${item.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('상태: ${item.status}'),
          Text('지점: ${item.branchName ?? '-'}'),
          Text('요청자: ${item.requesterName ?? '-'}'),
          Text('접수일: ${_fmt(item.createdAt)}'),
          Text('제출일: ${_fmt(item.submittedAt)}'),
          const SizedBox(height: 16),
          const Text('내용', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(item.description ?? '(내용 없음)'),
        ],
      ),
    );
  }
}
