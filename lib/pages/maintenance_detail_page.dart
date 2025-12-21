import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/detail_components/detail_provider.dart';
import 'package:juvis_faciliry/components/detail_photo_components/attachment_preview.dart';

class MaintenanceDetailPage extends ConsumerWidget {
  final int maintenanceId;

  const MaintenanceDetailPage({super.key, required this.maintenanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(maintenanceDetailProvider(maintenanceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('요청 상세'),
        centerTitle: true,
        leadingWidth: 90, // ← 중요
        leading: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.list_alt, size: 20),
                SizedBox(width: 4),
                Text('목록', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('상세 불러오기 실패: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: d.status, icon: Icons.info_outline),
                        _MetaChip(
                          label: d.categoryName,
                          icon: Icons.category_outlined,
                        ),
                        if (d.createdAt != null)
                          _MetaChip(
                            label: _fmtDateTime(d.createdAt!),
                            icon: Icons.calendar_today_outlined,
                          ),
                      ],
                    ),
                    if ((d.rejectedReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '반려 사유: ${d.rejectedReason}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: '지점 / 요청자',
              children: [
                _kv('지점', d.branchName),
                _kv('주소', d.branchAddress),
                const Divider(height: 22),
                _kv('요청자', d.requesterName),
                _kv('연락처', d.requesterPhone),
              ],
            ),

            const SizedBox(height: 12),
            const SizedBox(height: 12),
            _sectionCard(
              title: '요청 내용',
              children: [
                _kv('설명', d.description),
                const Divider(height: 22),
                _kv(
                  '제출일',
                  d.submittedAt == null ? null : _fmtDateTime(d.submittedAt!),
                ),
                _kv(
                  '업체 제출일',
                  d.vendorSubmittedAt == null
                      ? null
                      : _fmtDateTime(d.vendorSubmittedAt!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: '붙임파일',
              children: [
                AttachmentPreview(
                  imageUrls: d.attachPhotoUrls, // 나중에 연결
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: '업체 / 견적 / 작업기간',
              children: [
                _kv('업체명', d.vendorName),
                _kv('업체 연락처', d.vendorPhone),
                const Divider(height: 22),
                _kv(
                  '견적금액',
                  d.estimateAmount == null
                      ? null
                      : '${_fmtMoney(d.estimateAmount!)} 원',
                ),
                _kv('견적 코멘트', d.estimateComment),
                const Divider(height: 22),
                _kv(
                  '작업 시작',
                  d.workStartDate == null ? null : _fmtDate(d.workStartDate!),
                ),
                _kv(
                  '작업 종료',
                  d.workEndDate == null ? null : _fmtDate(d.workEndDate!),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _sectionCard(
              title: '결과 / 승인',
              children: [
                _kv('결과 코멘트', d.resultComment),
                _kv(
                  '작업 완료',
                  d.workCompletedAt == null
                      ? null
                      : _fmtDateTime(d.workCompletedAt!),
                ),
                const SizedBox(height: 10),
                if ((d.resultPhotoUrl ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1.6,
                      child: Image.network(
                        d.resultPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text('사진을 불러올 수 없습니다.')),
                      ),
                    ),
                  )
                else
                  const Text('등록된 결과 사진이 없습니다.'),
                const Divider(height: 22),
                _kv('승인자', d.approvedByName),
                _kv(
                  '승인일',
                  d.approvedAt == null ? null : _fmtDateTime(d.approvedAt!),
                ),
              ],
            ),
          ],
        ),
      ),
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

  static Widget _kv(String k, String? v) {
    final value = (v == null || v.isEmpty) ? '-' : v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  static String _fmtDateTime(DateTime dt) =>
      "${_fmtDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  static String _fmtMoney(String raw) {
    final s = raw.split('.').first;
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remain = s.length - i;
      sb.write(s[i]);
      if (remain > 1 && remain % 3 == 1) sb.write(',');
    }
    return sb.toString();
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
