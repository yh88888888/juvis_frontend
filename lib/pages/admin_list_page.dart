import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/admin_components/admin_list_models.dart';
import 'package:juvis_faciliry/components/admin_components/admin_list_provider.dart';
import 'package:juvis_faciliry/pages/maintenance_detail_page.dart';

class HqRequestListPage extends ConsumerStatefulWidget {
  const HqRequestListPage({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  ConsumerState<HqRequestListPage> createState() => _HqRequestListPageState();
}

class _HqRequestListPageState extends ConsumerState<HqRequestListPage> {
  late HqListQuery q;

  @override
  void initState() {
    super.initState();
    q = HqListQuery(page: 0, size: 20, status: widget.initialStatus);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPage = ref.watch(hqRequestListProvider(q));

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForStatus(q.status)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(hqRequestListProvider(q)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: asyncPage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('목록 불러오기 실패: $e')),
        data: (page) {
          final items = [...page.content];

          // ✅ 요청일(submittedAt) 최신순 (없으면 createdAt 대체)
          items.sort((a, b) {
            final ad =
                a.submittedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bd =
                b.submittedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

          return Column(
            children: [
              _filterBar(context),
              _tableHeader(),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('문서가 없습니다.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == items.length) return _pager(page);

                          final it = items[index];
                          return _RowCard(
                            submittedAt: it.submittedAt ?? it.createdAt,
                            branchName: it.branchName ?? '-',
                            title: it.title,
                            status: it.status,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MaintenanceDetailPage(
                                    maintenanceId: it.id,
                                  ),
                                ),
                              );

                              // ✅ 상세에서 변경이 있었다면:
                              // 1) 현재 리스트도 최신화(선택)
                              // 2) AdminAppPage까지 true를 전달해서 요약 갱신 트리거
                              if (changed == true) {
                                ref.invalidate(
                                  hqRequestListProvider(q),
                                ); // 리스트도 새로고침 (선택이지만 추천)
                                if (!mounted) return;
                                Navigator.pop(
                                  context,
                                  true,
                                ); // 🔥 이게 핵심 (AdminAppPage로 전달)
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------
  // 필터바 (⚠️ status null 복귀 문제 우회: copyWith(status: null) 안 씀)
  // --------------------------
  Widget _filterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: Colors.black.withOpacity(0.03),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    '지점요청',
                    isOn: q.status == 'REQUESTED',
                    onTap: () => _setStatus('REQUESTED'),
                  ),

                  _chip(
                    '견적대기',
                    isOn: q.status == 'ESTIMATING',
                    onTap: () => _setStatus('ESTIMATING'),
                  ),
                  _chip(
                    '견적제출',
                    isOn: q.status == 'APPROVAL_PENDING',
                    onTap: () => _setStatus('APPROVAL_PENDING'),
                  ),
                  _chip(
                    '작업중',
                    isOn: q.status == 'IN_PROGRESS',
                    onTap: () => _setStatus('IN_PROGRESS'),
                  ),
                  _chip(
                    '완료',
                    isOn: q.status == 'COMPLETED',
                    onTap: () => _setStatus('COMPLETED'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setStatus(String? status) {
    // ✅ copyWith(status: null) 구현 문제로 전체 복귀가 안 되는 케이스를 피하기 위해
    // 필터 변경 시에는 쿼리 객체를 "새로" 만든다.
    setState(() {
      q = HqListQuery(page: 0, size: q.size, status: status);
    });
  }

  Widget _chip(
    String label, {
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isOn ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isOn ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------
  // 헤더 (정렬 고정: RowCard와 동일 layout 상수 사용)
  // --------------------------
  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: const [
          SizedBox(width: _HqListLayout.leading),
          SizedBox(
            width: _HqListLayout.dateW,
            child: Text(
              '요청일',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _HqListLayout.gap),
          SizedBox(
            width: _HqListLayout.branchW,
            child: Text(
              '지점',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _HqListLayout.gap),
          SizedBox(
            width: 30,
            child: Text(
              '제목',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _HqListLayout.gap),
          SizedBox(
            width: _HqListLayout.statusW,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '상태',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // 페이징
  // --------------------------
  Widget _pager(PageDTO<HqRequestItem> page) {
    // totalPages가 null/0으로 올 때 방어
    final totalPages = (page.totalPages <= 0) ? 1 : page.totalPages;

    // ✅ 페이지가 1페이지면 페이징 자체 숨김
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    // q.page는 0-based, 화면 표시는 1-based
    final currentPage = (q.page + 1).clamp(1, totalPages);

    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canPrev
                  ? () => setState(() => q = q.copyWith(page: currentPage - 2))
                  : null,
              child: Text('이전 ($currentPage)'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: canNext
                  ? () => setState(() => q = q.copyWith(page: currentPage))
                  : null,
              child: Text('다음 ($currentPage/$totalPages)'),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // 타이틀
  // --------------------------
  String _titleForStatus(String? status) {
    // 기존 HQ 로직
    switch ((status ?? '').toUpperCase()) {
      case 'REQUESTED':
        return '지점 요청(결재 대기)';
      case 'ESTIMATING':
        return '업체 견적 대기';
      case 'APPROVAL_PENDING':
        return '견적 제출(승인 대기)';
      case 'IN_PROGRESS':
        return '작업 중';
      case 'COMPLETED':
        return '작업 완료';
      default:
        return '전체 문서';
    }
  }

  static String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

class _HqListLayout {
  static const double leading = 16; // 왼쪽바+여백 영역(항상 고정)
  static const double dateW = 86;
  static const double branchW = 78;
  static const double statusW = 110;
  static const double gap = 6;
}

// ==============================
// 한 줄 카드 UI (Chip + 승인대상 강조)
// 승인대상: REQUESTED(지점 승인대기), APPROVAL_PENDING(견적 승인대기)
// ==============================
class _RowCard extends StatelessWidget {
  final DateTime? submittedAt;
  final String branchName;
  final String title;
  final String status;
  final VoidCallback onTap;

  const _RowCard({
    required this.submittedAt,
    required this.branchName,
    required this.title,
    required this.status,
    required this.onTap,
  });

  bool get _isApprovalTarget {
    final s = status.trim().toUpperCase();
    return s == 'REQUESTED' || s == 'APPROVAL_PENDING';
  }

  static Color _barColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'REQUESTED') return Colors.redAccent;
    if (s == 'APPROVAL_PENDING') return Colors.blue; // ✅ 견적 승인대상
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = submittedAt == null
        ? '-'
        : _HqRequestListPageState._fmtDate(submittedAt!);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _isApprovalTarget ? Colors.black.withOpacity(0.03) : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                // ✅ 항상 leading 폭을 확보(바 유무와 상관없이)
                SizedBox(
                  width: _HqListLayout.leading,
                  child: _isApprovalTarget
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 5,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _barColor(status),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        )
                      : null,
                ),

                SizedBox(
                  width: _HqListLayout.dateW,
                  child: Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: _HqListLayout.gap),

                SizedBox(
                  width: _HqListLayout.branchW,
                  child: Text(
                    branchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: _HqListLayout.gap),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _isApprovalTarget
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: _HqListLayout.gap),

                SizedBox(
                  width: _HqListLayout.statusW,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _StatusChip(status: status),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================
// 상태 Chip/Badge
// ==============================
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static String _norm(String s) => s.trim().toUpperCase();

  static String label(String s) {
    switch (_norm(s)) {
      case 'REQUESTED':
        return '지점 승인대기';
      case 'ESTIMATING':
        return '견적산정중';
      case 'APPROVAL_PENDING':
        return '견적 승인대기'; // ✅ 승인대상으로 표시
      case 'IN_PROGRESS':
        return '작업중';
      case 'COMPLETED':
        return '완료';
      case 'HQ1_REJECTED':
        return '1차 반려';
      case 'HQ2_REJECTED':
        return '견적 반려';
      default:
        return s;
    }
  }

  static Color fg(String s) {
    switch (_norm(s)) {
      case 'REQUESTED':
        return Colors.redAccent;
      case 'ESTIMATING':
        return Colors.orange;
      case 'APPROVAL_PENDING':
        return Colors.blue; // ✅ 승인대상(견적)
      case 'IN_PROGRESS':
        return Colors.deepPurple;
      case 'COMPLETED':
        return Colors.green;
      case 'HQ1_REJECTED':
      case 'HQ2_REJECTED':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  static Color bg(String s) => fg(s).withOpacity(0.10);

  @override
  Widget build(BuildContext context) {
    final text = label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg(status).withOpacity(0.30)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: fg(status),
        ),
      ),
    );
  }
}
