import 'package:flutter/material.dart';

class AdminAppPage extends StatelessWidget {
  const AdminAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String name = args?['name'] ?? '이름 없음';
    final int? userId = args?['userId'];

    return Scaffold(
      appBar: AppBar(title: const Text('관리자 페이지')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 인사
          Text(
            '$name (HQ)',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (userId != null)
            Text(
              'User ID: $userId',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 16),

          // 요약 카드 영역
          Row(
            children: const [
              Expanded(child: _SummaryCard(title: '결재 대기', count: 3)),
              SizedBox(width: 8),
              Expanded(child: _SummaryCard(title: '미확인 문서', count: 7)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _SummaryCard(title: '오늘 기안', count: 2)),
              SizedBox(width: 8),
              Expanded(child: _SummaryCard(title: '완료 문서', count: 15)),
            ],
          ),
          const SizedBox(height: 24),

          // 최신 문서 리스트 (샘플)
          const Text(
            '최신 문서',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const _RecentDocItem(
            title: '[왕십리점/인테리어 교체] 공사 요청',
            status: '결재 대기',
            docNo: '20251023P348-0065',
            drafter: '조세빈',
            date: '2025.10.23',
          ),
          const _RecentDocItem(
            title: '[대구죽전점/인테리어 수리] 견적 요청',
            status: '진행중',
            docNo: '20251022P348-0112',
            drafter: '권성준',
            date: '2025.10.22',
          ),
          const _RecentDocItem(
            title: '[관악점/인테리어 수리] 상판 교체',
            status: '완료',
            docNo: '20251021P348-0091',
            drafter: '김하연',
            date: '2025.10.21',
          ),

          const SizedBox(height: 24),

          // 전체 문서 보기 (웹 연결 또는 추후 구현)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: WebView 또는 외부 브라우저로 관리자 페이지 열기
                // 예: url_launcher 패키지로 https://juvis-admin... 열기
              },
              child: const Text('전체 문서 웹에서 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;

  const _SummaryCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$docNo · $drafter · $date'),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == '결재 대기'
                ? Colors.red
                : (status == '진행중' ? Colors.orange : Colors.green),
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          // TODO: 문서 상세 화면으로 이동 or 웹뷰
        },
      ),
    );
  }
}
