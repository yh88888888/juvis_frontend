import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/_core/util/auth_request.dart';
import 'package:juvis_faciliry/config/api_config.dart';

class MaintenanceSimpleItem {
  final int id;
  final String? branchName;
  final String? requesterName;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime? submittedAt;

  MaintenanceSimpleItem({
    required this.id,
    required this.branchName,
    required this.requesterName,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.submittedAt,
  });

  factory MaintenanceSimpleItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceSimpleItem(
      id: (json['id'] as num).toInt(),
      branchName: json['branchName'] as String?,
      requesterName: json['requesterName'] as String?,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
    );
  }
}

/// 🟣 최신 3개 불러오기 위젯 (지점 최신 요청 3건)
class LatestBoardSection extends ConsumerStatefulWidget {
  const LatestBoardSection({super.key});

  @override
  ConsumerState<LatestBoardSection> createState() => _LatestBoardSectionState();
}

class _LatestBoardSectionState extends ConsumerState<LatestBoardSection> {
  bool _loading = true;
  String? _error;

  List<MaintenanceSimpleItem> _items = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ 최신 3개: page=0&size=3 (정렬은 서버 기본/서비스 강제 로직으로 createdAt DESC)
      final uri = Uri.parse("$apiBase/api/branch/maintenances?page=0&size=3");

      final res = await authRequest((token) {
        return http.get(
          uri,
          headers: {
            'Authorization': token, // token이 "Bearer ..." 형태면 그대로 OK
            'Content-Type': 'application/json',
          },
        );
      });

      if (res.statusCode != 200) {
        throw Exception('서버 오류: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      // Resp.ok(...) => {status,msg,body:{content:[...]}}
      final body = decoded['body'] as Map<String, dynamic>;
      final content = (body['content'] as List)
          .map((e) => MaintenanceSimpleItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _items = content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "데이터를 불러오지 못했습니다";
        _loading = false;
      });
    }
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '미정';
    // 간단 포맷(yyyy-MM-dd HH:mm) - intl 없이
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (_items.isEmpty) {
      return const Center(
        child: Text("신청된 내역이 없습니다.", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ 핵심
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/maintenance-detail',
                    arguments: {'id': item.id},
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9EE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '접수내용',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              " ${item.title}",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _KvRow(title: "상태:", value: "${item.status}"),
                        _KvRow(
                          title: "제출일:",
                          value: "${_fmtDateTime(item.submittedAt)}",
                        ),
                        // _KvRow(
                        //   title: "방문예정일:",
                        //   value: "${_fmtDateTime(item.workStartDate)}",
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // 🔵 점 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (_, __) {
                  int current = 0;
                  if (_pageController.hasClients &&
                      _pageController.page != null) {
                    current = _pageController.page!.round();
                  }
                  final isActive = current == index;

                  return Container(
                    margin: const EdgeInsets.all(6),
                    width: isActive ? 12 : 8,
                    height: isActive ? 12 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  final String title;
  final String value;

  const _KvRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
