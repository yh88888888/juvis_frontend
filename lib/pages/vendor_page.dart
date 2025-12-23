import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_bottom_bar.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_summary_provider.dart';

class VendorPage extends ConsumerWidget {
  const VendorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // ✅ "아이디 진정성" 표시용: username > name > id
    final vendorLabel =
        session?.username ??
        session?.name ??
        (session?.id != null ? 'ID: ${session!.id}' : '업체 계정');

    final asyncSummary = ref.watch(vendorSummaryProvider);

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
                    const TextSpan(
                      text: '   업체 페이지\n',
                      style: TextStyle(
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
              const SizedBox(height: 12),

              // ✅ 아이디 진정성 카드 (AdminAppPage 느낌 그대로)
              _sectionCard(
                title: '업체 계정',
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vendorLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ 카드 3개만
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '견적 제출 필요',
                      // AdminAppPage에서 "견적 대기"가 s.estimating 사용 :contentReference[oaicite:1]{index=1}
                      count: s.estimating,
                      onTap: () => _goList(context, 'ESTIMATING'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: '작업 중(결과제출 필요)',
                      count: s.inProgress,
                      // ✅ 요구: "작업 중 카드도 누르면 같은곳으로 가야"
                      // → 같은 리스트로 이동(필터만 IN_PROGRESS)
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

              _sectionCard(
                title: '<업체 안내>',
                children: const [
                  Text('• 견적 제출 필요: 본사 1차 승인 후 견적/작업가능일을 입력합니다.'),
                  SizedBox(height: 6),
                  Text('• 작업 중(결과제출 필요): 작업 완료 후 결과/사진 제출을 진행합니다.'),
                  SizedBox(height: 6),
                  Text('• 작업 완료: 제출한 완료자료가 확정된 상태입니다.'),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const VendorBottomBar(),
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

  void _goList(BuildContext context, String? status) {
    Navigator.pushNamed(context, '/vendor-list');
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;

  const _SummaryCard({required this.title, required this.count, this.onTap});

  Color _countColor() {
    switch (title) {
      case '견적 제출 필요':
        return Colors.orange;
      case '작업 중(결과제출 필요)':
        return Colors.blueAccent;
      case '작업 완료':
        return Colors.green;
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
                  color: _countColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
