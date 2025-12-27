import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_list_provider.dart';

class VendorListPage extends ConsumerStatefulWidget {
  const VendorListPage({super.key});

  @override
  ConsumerState<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends ConsumerState<VendorListPage> {
  String? _status; // null = 전체

  @override
  void initState() {
    super.initState();

    // VendorPage에서 Navigator.pushNamed(..., arguments: status) 로 넘어온 값 받기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg == null) return;

      if (arg is String) {
        setState(() => _status = arg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(vendorListProvider(_status));

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForStatus(_status)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(vendorListProvider(_status)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('목록 불러오기 실패: $e')),
        data: (dto) {
          final items = [...dto.items];

          // 최신순
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              _filterBar(),
              _tableHeader(),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('문서가 없습니다.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final it = items[index];
                          return _RowCard(
                            createdAt: it.createdAt,
                            branchName: it.branchName ?? '-',
                            title: it.title,
                            status: it.status,
                            onTap: () async {
                              // 기존 상세 라우트 그대로 사용
                              final changed = await Navigator.pushNamed(
                                context,
                                '/detail',
                                arguments: it.id,
                              );

                              if (changed == true) {
                                ref.invalidate(vendorListProvider(_status));
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
  // 필터바
  // --------------------------
  Widget _filterBar() {
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
                    '전체',
                    isOn: _status == null,
                    onTap: () => _setStatus(null),
                  ),
                  _chip(
                    '견적 제출 필요',
                    isOn: _status == 'ESTIMATING',
                    onTap: () => _setStatus('ESTIMATING'),
                  ),
                  _chip(
                    '견적 반려',
                    isOn: _status == 'HQ2_REJECTED',
                    onTap: () => _setStatus('HQ2_REJECTED'),
                  ),
                  _chip(
                    '승인 대기',
                    isOn: _status == 'APPROVAL_PENDING',
                    onTap: () => _setStatus('APPROVAL_PENDING'),
                  ),
                  _chip(
                    '작업중',
                    isOn: _status == 'IN_PROGRESS',
                    onTap: () => _setStatus('IN_PROGRESS'),
                  ),
                  _chip(
                    '완료',
                    isOn: _status == 'COMPLETED',
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

  void _setStatus(String? s) {
    setState(() => _status = s);
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
  // 테이블 헤더
  // --------------------------
  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: const [
          SizedBox(width: _VendorListLayout.leading),
          SizedBox(
            width: _VendorListLayout.dateW,
            child: Text(
              '요청일',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _VendorListLayout.gap),
          SizedBox(
            width: _VendorListLayout.branchW,
            child: Text(
              '지점',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _VendorListLayout.gap),
          SizedBox(
            width: 30,
            child: Text(
              '제목',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(width: _VendorListLayout.gap),
          SizedBox(
            width: _VendorListLayout.statusW,
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
  // 타이틀
  // --------------------------
  String _titleForStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ESTIMATING':
        return '견적 제출 필요';
      case 'APPROVAL_PENDING':
        return '승인 대기';
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

class _VendorListLayout {
  static const double leading = 16;
  static const double dateW = 86;
  static const double branchW = 78;
  static const double statusW = 110;
  static const double gap = 6;
}

/// ==============================
/// Row card UI
/// ==============================
class _RowCard extends StatelessWidget {
  final DateTime createdAt;
  final String branchName;
  final String title;
  final String status;
  final VoidCallback onTap;

  const _RowCard({
    required this.createdAt,
    required this.branchName,
    required this.title,
    required this.status,
    required this.onTap,
  });

  bool get _isActionTarget {
    final s = status.trim().toUpperCase();
    // Vendor 입장에서 "내가 해야 할 액션" 강조
    return s == 'ESTIMATING' || s == 'HQ2_REJECTED' || s == 'IN_PROGRESS';
  }

  static Color _barColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'ESTIMATING') return Colors.orange;
    if (s == 'HQ2_REJECTED') return Colors.grey;
    if (s == 'IN_PROGRESS') return Colors.deepPurple;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _VendorListPageState._fmtDate(createdAt);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _isActionTarget ? Colors.black.withOpacity(0.03) : null,
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
                SizedBox(
                  width: _VendorListLayout.leading,
                  child: _isActionTarget
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
                  width: _VendorListLayout.dateW,
                  child: Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: _VendorListLayout.gap),
                SizedBox(
                  width: _VendorListLayout.branchW,
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
                const SizedBox(width: _VendorListLayout.gap),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _isActionTarget
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: _VendorListLayout.gap),
                SizedBox(
                  width: _VendorListLayout.statusW,
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

/// ==============================
/// Status chip
/// ==============================
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static String _norm(String s) => s.trim().toUpperCase();

  static String label(String s) {
    switch (_norm(s)) {
      case 'ESTIMATING':
        return '견적 제출 필요';
      case 'APPROVAL_PENDING':
        return '승인 대기';
      case 'IN_PROGRESS':
        return '작업중';
      case 'COMPLETED':
        return '완료';
      default:
        return s;
    }
  }

  static Color fg(String s) {
    switch (_norm(s)) {
      case 'ESTIMATING':
        return Colors.orange;
      case 'APPROVAL_PENDING':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.deepPurple;
      case 'COMPLETED':
        return Colors.green;
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
