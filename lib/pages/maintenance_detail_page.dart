import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/detail_components/detail_provider.dart';
import 'package:juvis_faciliry/components/detail_photo_components/attachment_preview.dart';

enum AppRole { branch, vendor, hq, unknown }

class MaintenanceDetailPage extends ConsumerWidget {
  final int maintenanceId;

  const MaintenanceDetailPage({super.key, required this.maintenanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final role = _resolveRole(session?.role);

    final asyncDetail = ref.watch(maintenanceDetailProvider(maintenanceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세내용'),
        centerTitle: true,
        leadingWidth: 90,
        leading: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
        data: (d) {
          // ✅ HQ는 Draft/Requested 모두 조회 가능
          // (더 이상 상세페이지에서 막지 않음)
          final children = <Widget>[
            const SizedBox(height: 12),
            _roleBanner(role),
            const SizedBox(height: 12),

            if (role == AppRole.branch) ...[
              _workflowHintCard(),
              const SizedBox(height: 12),
              _branchSingleCard(d),
              const SizedBox(height: 12),
            ] else ...[
              _topSummaryCard(d),
              const SizedBox(height: 12),

              // ✅ 1) HQ 1차 검토: HQ 액션은 Requested일 때만 노출
              _sectionCard(
                title: '1) HQ 1차 검토 (Requested → Approved/Rejected)',
                children: [
                  _kv('현재 상태', d.status),
                  _kv('HQ 1차 승인일(예정)', _fmtNullableDateTime(d.approvedAt)),
                  _kv('HQ 1차 반려사유(예정)', d.rejectedReason),
                  const SizedBox(height: 10),

                  if (role == AppRole.hq) ...[
                    if (_isRequested(d.status)) ...[
                      _actionRow(
                        context,
                        primaryText: '승인',
                        onPrimary: () {
                          // TODO: HQ 1차 승인 API
                        },
                        secondaryText: '코멘트 반려',
                        onSecondary: () {
                          // TODO: HQ 1차 반려(코멘트) API
                        },
                      ),
                    ] else ...[
                      _info('Draft 상태에서는 조회만 가능합니다. (Requested가 되면 승인/반려 가능)'),
                    ],
                  ] else
                    const Text('※ HQ만 승인/반려 가능합니다.'),
                ],
              ),
              const SizedBox(height: 12),

              // 2) Vendor 견적/작업가능일 제출
              _sectionCard(
                title: '2) Vendor 견적/작업가능일 제출 (HQ 1차 승인 후)',
                children: [
                  _warning('재견적은 1회만 허용: 재제출 횟수/상태를 서버에서 내려주면 버튼 제어 가능'),
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
                    '작업 가능(시작)',
                    d.workStartDate == null ? null : _fmtDate(d.workStartDate!),
                  ),
                  _kv(
                    '작업 가능(종료)',
                    d.workEndDate == null ? null : _fmtDate(d.workEndDate!),
                  ),
                  _kv(
                    '업체 제출일',
                    d.vendorSubmittedAt == null
                        ? null
                        : _fmtDateTime(d.vendorSubmittedAt!),
                  ),
                  const SizedBox(height: 10),
                  if (role == AppRole.vendor) ...[
                    _actionRow(
                      context,
                      primaryText: '견적/일정 제출 (HQ로)',
                      onPrimary: () {
                        // TODO: Vendor 제출 API
                      },
                      secondaryText: '견적 재제출 (1회)',
                      onSecondary: () {
                        // TODO: Vendor 재제출 API (서버에서 1회 제한)
                      },
                    ),
                  ] else if (role == AppRole.branch) ...[
                    const Text('※ Branch는 HQ 승인 상태/날짜만 확인합니다.'),
                  ] else ...[
                    const Text('※ HQ는 Vendor 제출 내용을 검토합니다.'),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 3) HQ 2차 승인
              _sectionCard(
                title: '3) HQ 2차 승인 (Vendor 제출 검토)',
                children: [
                  _warning('필드 미확정: 2차 승인일/2차 반려사유 별도 필드 권장'),
                  _kv('HQ 2차 승인일(예정)', _fmtNullableDateTime(d.approvedAt)),
                  _kv('HQ 2차 반려사유(예정)', d.rejectedReason),
                  const SizedBox(height: 10),
                  if (role == AppRole.hq) ...[
                    // ✅ 여기서도 "Vendor 제출 상태일 때만" 버튼 노출이 이상적이지만
                    // 지금은 상태 체계가 확정 전이니 임시로 항상 노출하지 않고 경고로 둠
                    _info('TODO: Vendor 제출 상태일 때만 HQ 2차 승인/반려 버튼 노출'),
                    _actionRow(
                      context,
                      primaryText: '승인',
                      onPrimary: () {
                        // TODO: HQ 2차 승인 API
                      },
                      secondaryText: '코멘트 반려',
                      onSecondary: () {
                        // TODO: HQ 2차 반려 API
                      },
                    ),
                  ] else
                    const Text('※ HQ만 승인/반려 가능합니다.'),
                ],
              ),
              const SizedBox(height: 12),

              // 4) 작업 완료
              _sectionCard(
                title: '4) 작업 완료 (Vendor 사진 + 완료일 제출) → 종료',
                children: [
                  _kv('작업 완료일', _fmtNullableDateTime(d.workCompletedAt)),
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
                  const SizedBox(height: 10),
                  if (role == AppRole.vendor) ...[
                    _actionRow(
                      context,
                      primaryText: '작업완료 제출',
                      onPrimary: () {
                        // TODO: Vendor 작업완료 제출 API
                      },
                      secondaryText: '사진 추가/수정',
                      onSecondary: () {
                        // TODO: 사진 첨부 플로우 연결
                      },
                    ),
                  ] else
                    const Text('※ Vendor 작업 완료 제출 후 종료됩니다.'),
                ],
              ),
            ],
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          );
        },
      ),
    );
  }

  // --------------------------
  // Branch 단일 카드
  // --------------------------
  static Widget _branchSingleCard(dynamic d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: d.status, icon: Icons.info_outline),
                _MetaChip(label: d.categoryName, icon: Icons.category_outlined),
                if (d.createdAt != null)
                  _MetaChip(
                    label: _fmtDateTime(d.createdAt!),
                    icon: Icons.calendar_today_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('지점', d.branchName),
            _kv('주소', d.branchAddress),
            _kv('연락처', d.requesterPhone),
            _kv('상세내용', d.description),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '붙임파일',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                AttachmentPreview(imageUrls: d.attachPhotoUrls),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------
  // HQ/Vendor 상단 요약 카드
  // --------------------------
  static Widget _topSummaryCard(dynamic d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: d.status, icon: Icons.info_outline),
                _MetaChip(label: d.categoryName, icon: Icons.category_outlined),
                if (d.createdAt != null)
                  _MetaChip(
                    label: _fmtDateTime(d.createdAt!),
                    icon: Icons.calendar_today_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('지점', d.branchName),
            _kv('주소', d.branchAddress),
            const Divider(height: 22),
            _kv('요청자', d.requesterName),
            _kv('연락처', d.requesterPhone),
            const Divider(height: 22),
            _kv('설명', d.description),
            const SizedBox(height: 10),
            const Text(
              '붙임파일',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            AttachmentPreview(imageUrls: d.attachPhotoUrls),
          ],
        ),
      ),
    );
  }

  // --------------------------
  // 공통 UI
  // --------------------------
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
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static Widget _warning(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
    );
  }

  static Widget _info(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
    );
  }

  static Widget _actionRow(
    BuildContext context, {
    required String primaryText,
    required VoidCallback onPrimary,
    required String secondaryText,
    required VoidCallback onSecondary,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(onPressed: onPrimary, child: Text(primaryText)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondary,
            child: Text(secondaryText),
          ),
        ),
      ],
    );
  }

  static Widget _roleBanner(AppRole role) {
    String label;
    IconData icon;
    switch (role) {
      case AppRole.branch:
        label = '지점 전용';
        icon = Icons.storefront;
        break;
      case AppRole.vendor:
        label = '업체 전용';
        icon = Icons.handyman;
        break;
      case AppRole.hq:
        label = '본사 전용';
        icon = Icons.apartment;
        break;
      default:
        label = 'UNKNOWN ROLE';
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Widget _workflowHintCard() {
    return _sectionCard(
      title: '<진행 순서 안내>',
      children: const [
        Text('• 지점: 요청서 저장 → 제출'),
        SizedBox(height: 6),
        Text('• 본사: 승인 or 코멘트 입력하여 반려'),
        SizedBox(height: 6),
        Text('• (본사 → 지점승인) 관리업체: 견적가/작업가능일 제출'),
        SizedBox(height: 6),
        Text('• 본사: 견적 승인 - 지점: 작업가능일/관리업체 연락처 확인'),
        SizedBox(height: 6),
        Text('• (본사 → 견적승인) 관리업체: 완료사진 + 완료일 제출'),
        SizedBox(height: 6),
        Text('• (본사 → 견적반려) 관리업체: 재견적 1회 가능'),
      ],
    );
  }

  // --------------------------
  // 상태/역할 판별
  // --------------------------
  static bool _isRequested(String status) {
    final s = status.trim().toUpperCase();
    return s == 'REQUESTED';
  }

  static AppRole _resolveRole(dynamic rawRole) {
    final s = (rawRole?.toString() ?? '').toUpperCase();
    if (s.contains('BRANCH')) return AppRole.branch;
    if (s.contains('VENDOR')) return AppRole.vendor;
    if (s.contains('HQ')) return AppRole.hq;
    return AppRole.unknown;
  }

  static String _fmtNullableDateTime(DateTime? dt) =>
      dt == null ? '-' : _fmtDateTime(dt);

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
