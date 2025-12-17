import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/components/maintenance_components/maintenanceSimple.dart';
// import 'package:juvis_faciliry/config/api_config.dart'; // 있으면 여기서 baseUrl 가져오기

class MaintenanceListPage extends StatefulWidget {
  const MaintenanceListPage({super.key});

  @override
  State<MaintenanceListPage> createState() => _MaintenanceListPageState();
}

class _MaintenanceListPageState extends State<MaintenanceListPage> {
  static const softPink = Color(0xFFFFD1DC);
  static const softPinkBg = Color(0xFFFFE9EE);
  static const blueBtn = Color(0xFF2E66FF);

  final List<MaintenanceSimple> _items = [];
  bool _loading = true;
  String? _errorMsg;

  int _currentPage = 0; // 0-based
  int _totalPages = 1; // 최소 1

  // TODO: 실제 프로젝트에 맞게 baseUrl 수정
  final String _baseUrl = 'https://your-api-server.com';

  @override
  void initState() {
    super.initState();
    _fetchPage(0);
  }

  Future<void> _fetchPage(int page) async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final uri = Uri.parse(
        '$_baseUrl/api/branch/maintenances',
      ).replace(queryParameters: {'page': page.toString(), 'size': '20'});

      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // TODO: 필요하면 Authorization 헤더 추가 (JWT 등)
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 200) {
          final body = decoded['body'];
          final List<dynamic> content = body['content'];

          final items = content
              .map((e) => MaintenanceSimple.fromJson(e))
              .toList()
              .cast<MaintenanceSimple>();

          setState(() {
            _items
              ..clear()
              ..addAll(items);
            _currentPage = body['number'] as int;
            _totalPages = body['totalPages'] as int;
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
            _errorMsg = decoded['msg'] ?? '서버 응답 오류';
          });
        }
      } else {
        setState(() {
          _loading = false;
          _errorMsg = 'HTTP ${res.statusCode} 에러';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = '네트워크 오류: $e';
      });
    }
  }

  String _formatDate(DateTime dt) {
    // yyyy-MM-dd 형태
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    // 상태에 따라 뱃지 색상 다르게
    switch (status) {
      case 'REQUESTED':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildItemCard(MaintenanceSimple item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: id (작은 배지)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: softPinkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${item.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 오른쪽: 제목, 날짜, 상태
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 날짜
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // 상태 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(item.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(item.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    // 1 ~ totalPages 숫자 버튼
    final buttons = List<Widget>.generate(_totalPages, (index) {
      final isSelected = index == _currentPage;
      final display = index + 1; // 화면에는 1부터 보이게

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: isSelected ? blueBtn : Colors.white,
            side: BorderSide(
              color: isSelected ? blueBtn : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: () {
            if (!isSelected) {
              _fetchPage(index);
            }
          },
          child: Text(
            display.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: buttons),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final name = args?['name'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: softPinkBg,
        title: Text(
          name != '' ? '$name 님 요청 내역' : '유지보수 전체 목록',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Container(
        color: softPinkBg.withOpacity(0.4),
        child: Column(
          children: [
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMsg != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(_items[index]);
                  },
                ),
              ),
            // 아래 페이지 번호 영역
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}
