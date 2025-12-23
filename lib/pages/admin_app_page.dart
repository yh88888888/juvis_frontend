import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/admin_components/admin_summary_provider.dart';
import 'package:juvis_faciliry/components/admin_components/home_logout_bottom_bar.dart';
import 'package:juvis_faciliry/main.dart'; // ✅ routeObserver 가져오려고 (main.dart에 전역 선언해둔 것)
import 'package:juvis_faciliry/pages/admin_list_page.dart';

class AdminAppPage extends ConsumerStatefulWidget {
  const AdminAppPage({super.key});

  @override
  ConsumerState<AdminAppPage> createState() => _AdminAppPageState();
}

class _AdminAppPageState extends ConsumerState<AdminAppPage> with RouteAware {
  static const softPinkBg = Color(0xFFFFE9EE);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ✅ 다른 페이지 갔다가 "다시 이 화면이 보일 때" 호출됨
  @override
  void didPopNext() {
    _refreshSummary();
  }

  // ✅ 이 화면이 처음 push될 때도 한 번 갱신
  @override
  void didPush() {
    _refreshSummary();
  }

  Future<void> _refreshSummary() async {
    // invalidate만 해도 다시 fetch됨
    ref.invalidate(adminSummaryProvider);
    // 바로 재로딩 트리거까지 확실히
    await ref.read(adminSummaryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSummary = ref.watch(adminSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: softPinkBg,
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '쥬비스다이어트 ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9EB5),
                        height: 1.3,
                      ),
                    ),
                    TextSpan(
                      text: ' 관리자 페이지\n',
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
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softPinkBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.apartment, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSummary,
        child: asyncSummary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('요약 불러오기 실패: $e')),
            ],
          ),
          data: (s) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 30),

                /// ===== 1행 (2개) =====
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: '지점 요청',
                        count: s.requested,
                        onTap: () => _goList('REQUESTED'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: '견적 대기',
                        count: s.estimating,
                        onTap: () => _goList('ESTIMATING'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// ===== 2행 (3개) =====
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: '견적 제출',
                        count: s.approvalPending,
                        onTap: () => _goList('APPROVAL_PENDING'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: '작업 중',
                        count: s.inProgress,
                        onTap: () => _goList('IN_PROGRESS'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: '작업 완료',
                        count: s.completed,
                        onTap: () => _goList('COMPLETED'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// ===== 전체 버튼 (단독) =====
                _AllSummaryButton(
                  total:
                      s.requested +
                      s.estimating +
                      s.approvalPending +
                      s.inProgress +
                      s.completed,
                  onTap: () => _goList(null),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "<단계별 안내>",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('• [지점 요청] → 본사 승인필요\n  -  승인 or 코멘트 입력하여 반려'),
                        SizedBox(height: 6),
                        Text('• [견적 대기] → 업체에서 견적 중'),
                        SizedBox(height: 6),
                        Text(
                          '• [견적 제출] 관리업체: 견적가/작업가능일 제출\n  -  본사 승인 or 코멘트 입력하여 반려',
                        ),
                        SizedBox(height: 6),
                        Text('• [작업 중] 본사: 견적 승인 - 지점: 작업가능일/연락처 확인'),
                        SizedBox(height: 6),
                        Text('• [작업 완료] 관리업체: 완료사진 + 완료일 제출'),
                        SizedBox(height: 6),
                        Text('  * (본사 견적반려시) 관리업체: 재견적 1회 가능'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const HomeLogoutBottomBar(),
    );
  }

  void _goList(String? status) {
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
        return const Color(0xFFB71C1C); // 딥 레드
      case '견적 대기':
        return const Color(0xFFF9A825); // 머스터드 옐로우
      case '작업 중':
        return const Color(0xFF1565C0); // 로열 블루
      case '작업 완료':
        return const Color(0xFF616161); // 다크 그레이
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count건',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _countColor(), // ✅ 상태별 색상
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllSummaryButton extends StatelessWidget {
  final int total;
  final VoidCallback onTap;

  const _AllSummaryButton({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple,
              Colors.deepPurple,
              // Color(0xFF2B2B2B), // 다크 차콜
              // Color(0xFF1C1C1C),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '전체 목록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              '$total 건',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF9EB5), // 브랜드 핑크 포인트
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _countColorByTitle(String title) {
  switch (title) {
    case '지점 요청':
    case '견적 제출':
      return const Color(0xFFB71C1C); // 고급 딥 레드

    case '견적 대기':
      return const Color(0xFFF9A825); // 고급 머스터드 옐로우

    case '작업 중':
      return const Color(0xFF1565C0); // 차분한 로열 블루

    case '작업 완료':
      return const Color(0xFF616161); // 세련된 다크 그레이

    default:
      return Colors.black;
  }
}
