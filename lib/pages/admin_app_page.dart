import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/admin_components/admin_summary_provider.dart';
import 'package:juvis_faciliry/components/admin_components/home_logout_bottom_bar.dart';
import 'package:juvis_faciliry/pages/admin_list_page.dart'; // ✅ HqRequestListPage가 여기 있다고 가정

class AdminAppPage extends ConsumerWidget {
  const AdminAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String name = args?['name'] ?? '이름 없음';
    final int? userId = args?['userId'];

    final asyncSummary = ref.watch(adminSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '쥬비스다이어트',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9EB5),
                        height: 1.3,
                      ),
                    ),
                    TextSpan(
                      text: '   관리자 페이지\n',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const TextSpan(
                      text: '🔧 설비 유지 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        height: 1.4,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: asyncSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('요약 불러오기 실패: $e')),
        data: (s) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '지점 요청',
                      count: s.requested,
                      onTap: () => _goList(context, 'REQUESTED'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: '견적 대기',
                      count: s.estimating,
                      onTap: () => _goList(context, 'ESTIMATING'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '견적 제출',
                      count: s.approvalPending,
                      onTap: () => _goList(context, 'APPROVAL_PENDING'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: '작업 중',
                      count: s.inProgress,
                      onTap: () => _goList(context, 'IN_PROGRESS'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: '작업 완료',
                      count: s.completed,
                      onTap: () => _goList(context, 'COMPLETED'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _goList(context, null), // ✅ 전체
                  icon: const Icon(Icons.list_alt),
                  label: const Text(
                    '전체 문서 보기',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // TODO: 최신 문서도 서버에서 가져오려면 provider 추가
              _sectionCard(
                title: '<단계별 안내>',
                children: const [
                  Text('• 지점요청: 지점에서 요청서 제출\n  - 본사: 승인 or 코멘트 입력하여 반려\n'),
                  SizedBox(height: 6),
                  Text('• 업체 견적 대기: 지점요청 사항에 댛 본사 승인 \n     → 업체 견적중\n'),
                  SizedBox(height: 6),
                  Text(
                    '• 견적 제출: 관리업체 견적가/작업가능일 제출\n  - 본사: 승인 or 코멘트 입력하여 반려\n',
                  ),
                  SizedBox(height: 6),
                  Text('• 작업 중: 본사견적 승인 - 지점: 작업가능일/업체확인'),
                  SizedBox(height: 6),
                  Text('• 작업 완료: 업체 완료사진 + 완료일 제출'),
                  SizedBox(height: 6),
                  Text('• (본사 → 견적반려) 관리업체: 재견적 1회 가능'),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const HomeLogoutBottomBar(),
    );
  }

  static Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // ✅ context를 받도록 수정 (호출부와 일치)
  void _goList(BuildContext context, String? status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HqRequestListPage(initialStatus: status),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;

  const _SummaryCard({required this.title, required this.count, this.onTap});

  Color _countColor() {
    switch (title) {
      case '지점 요청':
      case '견적 제출':
        return Colors.redAccent;
      case '견적 대기':
        return Colors.orange; // 노란 느낌 (Material에서 가독성 좋음)
      case '작업 중':
        return Colors.blueAccent;
      default:
        return Colors.blueGrey;
    }
  }

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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _countColor(), // ✅ 여기 핵심
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
