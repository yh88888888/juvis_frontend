import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juvis_faciliry/components/admin_web_component/hq_doc.dart';
import 'package:juvis_faciliry/components/admin_web_component/hq_summary.dart';
import 'package:juvis_faciliry/config/api_config.dart';
import 'package:juvis_faciliry/pages/admin_list_page.dart';
import 'package:url_launcher/url_launcher.dart';

// -------------- HQ 모바일 페이지 --------------

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late String _name;
  late int _userId;

  bool _loading = true;
  String? _errorMsg;

  HqSummary? _summary;
  List<HqDoc> _recentDocs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // arguments에서 name, userId 가져오기
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    _name = args?['name'] ?? '이름 없음';
    _userId = args?['userId'] ?? 0;

    // 최초 1회만 로딩
    if (_loading) {
      _fetchDashboardData();
    }
  }

  void _goList(String? status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HqRequestListPage(initialStatus: status),
      ),
    );
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // 1) 요약 정보 호출
      final summaryUri = Uri.parse(
        '$apiBase/api/hq/summary',
      ).replace(queryParameters: {'userId': _userId.toString()});

      final summaryRes = await http.get(summaryUri);
      if (summaryRes.statusCode != 200) {
        throw Exception('요약 API 오류: ${summaryRes.statusCode}');
      }

      final summaryJson = jsonDecode(summaryRes.body) as Map<String, dynamic>;
      final summary = HqSummary.fromJson(summaryJson);

      // 2) 최신 문서 리스트 호출
      final docsUri = Uri.parse(
        '$apiBase/api/hq/recent-docs',
      ).replace(queryParameters: {'userId': _userId.toString(), 'limit': '5'});

      final docsRes = await http.get(docsUri);
      if (docsRes.statusCode != 200) {
        throw Exception('문서 목록 API 오류: ${docsRes.statusCode}');
      }

      final docsJson = jsonDecode(docsRes.body) as List<dynamic>;
      final docs = docsJson
          .map((e) => HqDoc.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recentDocs = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = '대시보드 데이터를 불러오지 못했습니다.\n$e';
        _loading = false;
      });
    }
  }

  // -------------- 전체 문서 웹으로 열기 (url_launcher) --------------

  Future<void> _openAdminWeb() async {
    // 실제 운영 관리자 웹 URL로 교체
    final url = Uri.parse('https://your-admin-web.com'); // TODO: 수정

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // 외부 브라우저로 열기
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('웹 페이지를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HQ 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchDashboardData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
          ? Center(child: Text(_errorMsg!, textAlign: TextAlign.center))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 인사
                Text(
                  '$_name 님 (HQ)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'User ID: $_userId',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // 요약 카드 영역
                if (summary != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: '결재 대기',
                          count: summary.pendingCount,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          title: '미확인 문서',
                          count: summary.unreadCount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: '오늘 기안',
                          count: summary.todayDraftCount,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          title: '완료 문서',
                          count: summary.completedCount,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // 최신 문서 리스트
                const Text(
                  '최신 문서',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_recentDocs.isEmpty)
                  const Text(
                    '최근 문서가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ..._recentDocs.map(
                    (doc) => _RecentDocItem(
                      title: doc.title,
                      status: doc.status,
                      docNo: doc.docNo,
                      drafter: doc.drafter,
                      date: doc.date,
                    ),
                  ),

                const SizedBox(height: 24),

                // 전체 문서 웹에서 보기 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openAdminWeb,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('전체 문서 웹에서 보기'),
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------- 하위 위젯들 --------------

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;

  const _SummaryCard({required this.title, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '$count건',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocItem extends StatelessWidget {
  final String title;
  final String status;
  final String docNo;
  final String drafter;
  final String date;

  const _RecentDocItem({
    required this.title,
    required this.status,
    required this.docNo,
    required this.drafter,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status) {
      case '결재 대기':
        statusColor = Colors.red;
        break;
      case '진행중':
        statusColor = Colors.orange;
        break;
      case '완료':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$docNo · $drafter · $date'),
        trailing: Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          // TODO: 문서 상세 화면 or 웹뷰로 이동
        },
      ),
    );
  }
}
