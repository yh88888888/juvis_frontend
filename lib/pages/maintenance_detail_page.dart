import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/_core/util/app_role.dart';
import 'package:juvis_faciliry/components/detail_components/detail_provider.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_api.dart';
import 'package:juvis_faciliry/components/detail_components/maintenance_detail_item.dart';
import 'package:juvis_faciliry/components/detail_photo_components/attachment_preview.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';
import 'package:juvis_faciliry/components/list_components/list_provider.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_summary_provider.dart';

class MaintenanceDetailPage extends ConsumerStatefulWidget {
  final int maintenanceId;

  const MaintenanceDetailPage({super.key, required this.maintenanceId});

  @override
  ConsumerState<MaintenanceDetailPage> createState() =>
      _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends ConsumerState<MaintenanceDetailPage> {
  bool _submittingEstimate = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final role = _resolveRole(session?.role);

    final asyncDetail = ref.watch(
      maintenanceDetailProvider((id: widget.maintenanceId, role: role)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            text: '상세 내용',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF9EB5),
              height: 1.3,
            ),
          ),
        ),
        centerTitle: true,
        leadingWidth: 90,
        leading: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context, true),
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
          final status = _normStatus(d.status);

          final children = <Widget>[
            const SizedBox(height: 12),
            _roleBanner(role),
            const SizedBox(height: 12),
            _workflowHintCard(),
            const SizedBox(height: 12),
            _topSummaryCard(d),
            const SizedBox(height: 12),

            if (_shouldShowHq1Card(status)) ...[
              _hq1ReviewCard(role, d),
              const SizedBox(height: 12),
            ],

            if (_shouldShowVendorEstimateCard(status)) ...[
              _vendorEstimateCard(role, d),
              const SizedBox(height: 12),
              if (status == 'HQ2_REJECTED') ...[
                _hq2ReviewCard(role, d),
                const SizedBox(height: 12),
              ],
            ],

            if (_shouldShowCompletedCard(status)) ...[
              _completedCard(role, d),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 110),
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          );
        },
      ),

      bottomNavigationBar: const HomeBottomNav(),

      bottomSheet: asyncDetail.when(
        loading: () => null,
        error: (_, __) => null,
        data: (d) => _buildActionBar(context, ref, role, d),
      ),
    );
  }

  // ============================================================
  // ✅ (A) 하단 액션바
  // ============================================================
  Widget? _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    MaintenanceDetailItem d,
  ) {
    final status = _normStatus(d.status);

    if (role == AppRole.hq && status == 'REQUESTED') {
      return _twoButtons(
        leftText: '반려',
        onLeft: () => _onHqRejectRequest(context, ref, role, d.id),
        rightText: '승인',
        onRight: () => _onHqApproveRequest(context, ref, role, d.id),
      );
    }

    if (role == AppRole.hq && status == 'APPROVAL_PENDING') {
      return _twoButtons(
        leftText: '반려',
        onLeft: () => _onHqRejectEstimate(context, ref, role, d.id),
        rightText: '승인',
        onRight: () => _onHqApproveEstimate(context, ref, role, d.id),
      );
    }

    final canVendorSubmit =
        role == AppRole.vendor &&
        (status == 'ESTIMATING' ||
            (status == 'HQ2_REJECTED' && d.estimateResubmitCount == 0));

    if (canVendorSubmit) {
      final btnText = (status == 'HQ2_REJECTED')
          ? '견적 재제출 (1회)'
          : '견적 / 작업일 입력';
      return _oneButton(
        text: btnText,
        onPressed: () => _submitEstimateFlow(context, ref, role, d),
      );
    }

    if (role == AppRole.vendor && status == 'IN_PROGRESS') {
      return _oneButton(
        text: '작업 완료 제출',
        onPressed: () => _onCompleteWork(context, ref, role, d.id),
      );
    }

    return null;
  }

  // ============================================================
  // ✅ (B) 견적 제출 플로우
  //   - 핵심 수정: 다이얼로그 컨트롤러 dispose는 다이얼로그 위젯 내부에서!
  // ============================================================
  Future<void> _submitEstimateFlow(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    MaintenanceDetailItem d,
  ) async {
    if (_submittingEstimate) return;

    final id = d.id;
    final statusAtTap = _normStatus(d.status);

    final canTap =
        role == AppRole.vendor &&
        (statusAtTap == 'ESTIMATING' ||
            (statusAtTap == 'HQ2_REJECTED' && d.estimateResubmitCount == 0));

    if (!canTap) {
      _snack(context, '견적 제출 불가 상태입니다. 현재: $statusAtTap');
      ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
      return;
    }

    // ✅ 입력 다이얼로그(컨트롤러는 다이얼로그가 소유/해제)
    final form = await _openEstimateDialog(context);
    if (form == null) return;

    // ✅ pop/키보드 정리 먼저 (타이밍 꼬임 방지)
    FocusManager.instance.primaryFocus?.unfocus();

    // 서버 truth로 한 번 더 확인
    try {
      final fresh = await ref.read(
        maintenanceDetailProvider((id: id, role: role)).future,
      );
      final freshStatus = _normStatus(fresh.status);

      final canSubmitNow =
          freshStatus == 'ESTIMATING' ||
          (freshStatus == 'HQ2_REJECTED' && fresh.estimateResubmitCount == 0);

      if (!canSubmitNow) {
        if (!context.mounted) return;
        _snack(context, '견적 제출 불가 상태입니다. 현재: $freshStatus');
        ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
        return;
      }
    } catch (_) {
      // fresh 실패해도 아래에서 시도는 진행
    }

    setState(() => _submittingEstimate = true);

    try {
      // ✅ await 전에 값 확보 (컨트롤러 접근 없음)
      final amount = form.amount;
      final comment = form.comment.isEmpty ? null : form.comment;
      final startDate = form.startDate;
      final endDate = form.endDate;

      final res = await MaintenanceDetailApi.submitEstimate(
        id: id,
        estimateAmount: amount,
        estimateComment: comment,
        workStartDate: startDate,
        workEndDate: endDate,
      );

      if (!context.mounted) return;

      if (res.statusCode == 200) {
        ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
        ref.invalidate(vendorSummaryProvider);
        // ✅ 🔥 목록 갱신 트리거
        ref.invalidate(maintenanceListProvider);
        _snack(context, '견적 제출 완료');
        return;
      }

      // 서버가 이미 APPROVAL_PENDING이면 UX는 "이미 제출됨"이 맞음
      try {
        final fresh = await ref.read(
          maintenanceDetailProvider((id: id, role: role)).future,
        );
        final freshStatus = _normStatus(fresh.status);
        ref.invalidate(maintenanceDetailProvider((id: id, role: role)));

        if (freshStatus == 'APPROVAL_PENDING') {
          _snack(context, '이미 제출되어 승인 대기 중입니다.');
          return;
        }
      } catch (_) {}

      ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
      _snack(context, '견적 제출 실패: ${res.statusCode}');
    } catch (e) {
      if (!context.mounted) return;
      ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
      _snack(context, '견적 제출 오류: $e');
    } finally {
      if (mounted) setState(() => _submittingEstimate = false);
    }
  }

  // ============================================================
  // ✅ (C) 다이얼로그: 입력만 받고 닫기
  //   - 핵심 수정: 컨트롤러 dispose를 여기서 하지 않는다!
  // ============================================================
  Future<_EstimateFormResult?> _openEstimateDialog(BuildContext context) async {
    return showDialog<_EstimateFormResult>(
      context: context,
      barrierDismissible: !_submittingEstimate,
      builder: (_) => const _EstimateDialog(),
    );
  }

  // ============================================================
  // ✅ 카드 표시 규칙
  // ============================================================
  static bool _shouldShowHq1Card(String status) {
    return status == 'REQUESTED' ||
        status == 'HQ1_REJECTED' ||
        status == 'ESTIMATING' ||
        status == 'APPROVAL_PENDING' ||
        status == 'HQ2_REJECTED' ||
        status == 'IN_PROGRESS' ||
        status == 'COMPLETED' ||
        status == 'DONE';
  }

  static bool _shouldShowVendorEstimateCard(String status) {
    return status == 'APPROVAL_PENDING' ||
        status == 'HQ2_REJECTED' ||
        status == 'IN_PROGRESS' ||
        status == 'COMPLETED' ||
        status == 'DONE';
  }

  static bool _shouldShowCompletedCard(String status) {
    return status == 'COMPLETED' || status == 'DONE';
  }

  // ============================================================
  // ✅ 카드 UI
  // ============================================================
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

  static Widget _hq1ReviewCard(AppRole role, MaintenanceDetailItem d) {
    final status = _normStatus(d.status);
    final reason = (d.requestRejectedReason ?? '').trim();

    final String result = () {
      if (status == 'REQUESTED') return '대기';
      if (status == 'HQ1_REJECTED') return '반려';
      if (d.requestApprovedAt != null) return '승인';
      return '처리됨';
    }();

    final bool showRejectReason =
        (status == 'HQ1_REJECTED' && reason.isNotEmpty);

    return _sectionCard(
      title: '본사 요청서 검토',
      children: [
        const Divider(height: 2, thickness: 1, color: Colors.blueGrey),
        const SizedBox(height: 6),
        _kv('1차 검토 결과', result),
        if (showRejectReason) _kv('반려 사유', reason, labelColor: Colors.red),
        _kv('결정자', d.requestApprovedByName),
        _kv('결정일', _fmtNullableDateTime(d.requestApprovedAt)),
        const SizedBox(height: 6),
        if (role == AppRole.hq)
          _info('요청서 제출에 대한 검토.')
        else
          _info('지점요청서 검토 사항입니다.'),
      ],
    );
  }

  static Widget _vendorEstimateCard(AppRole role, MaintenanceDetailItem d) {
    return _sectionCard(
      title: '견적 / 작업 정보',
      children: [
        const Divider(height: 2, thickness: 1, color: Colors.blueGrey),
        const SizedBox(height: 6),
        _kv('업체명', d.vendorName),
        _kv('업체 연락처', d.vendorPhone),
        const Divider(height: 15),
        _kv(
          '견적 금액',
          d.estimateAmount == null ? null : '${_fmtMoney(d.estimateAmount!)} 원',
        ),
        _kv('견적 코멘트', d.estimateComment),
        const Divider(height: 15),
        _kv(
          '시작예정일',
          d.workStartDate == null ? null : _fmtDate(d.workStartDate!),
        ),
        _kv('종료예정일', d.workEndDate == null ? null : _fmtDate(d.workEndDate!)),
        _kv(
          '견적 제출일',
          d.vendorSubmittedAt == null
              ? null
              : _fmtDateTime(d.vendorSubmittedAt!),
        ),
        if (role == AppRole.vendor) ...[
          _warning('재견적은 1회만 허용됩니다.'),
          _kv('재제출 횟수', '${d.estimateResubmitCount}'),
        ] else
          _info('업체 제출내용은 본사에서 검토합니다.'),
      ],
    );
  }

  static Widget _hq2ReviewCard(AppRole role, MaintenanceDetailItem d) {
    final status = _normStatus(d.status);
    final reason = (d.estimateRejectedReason ?? '').trim();

    final String result = () {
      if (status == 'APPROVAL_PENDING') return '대기';
      if (status == 'HQ2_REJECTED') return '반려';
      if (d.estimateApprovedAt != null) return '승인';
      return '처리됨';
    }();

    final bool showRejectReason =
        (status == 'HQ2_REJECTED' && reason.isNotEmpty);

    return _sectionCard(
      title: '본사 견적 검토',
      children: [
        const Divider(height: 2, thickness: 1, color: Colors.blueGrey),
        const SizedBox(height: 6),
        _kv('2차 검토 결과', result),
        if (showRejectReason) _kv('반려 사유', reason, labelColor: Colors.red),
        _kv('결정자', d.estimateApprovedByName),
        _kv('결정일', _fmtNullableDateTime(d.estimateApprovedAt)),
        const SizedBox(height: 6),
        if (role == AppRole.hq)
          _info('2차 검토는 APPROVAL_PENDING 상태에서 결정됩니다.')
        else
          _info('견적 검토 사항입니다.'),
      ],
    );
  }

  static Widget _completedCard(AppRole role, MaintenanceDetailItem d) {
    return _sectionCard(
      title: '작업 결과',
      children: [
        const Divider(height: 2, thickness: 1, color: Colors.blueGrey),
        const SizedBox(height: 6),
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
        _kv('완료 코멘트', d.resultComment),
      ],
    );
  }

  static Widget _topSummaryCard(MaintenanceDetailItem d) {
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
                _MetaChip(
                  label: "[${maintenanceStatusLabel(_normStatus(d.status))}]",
                  icon: Icons.priority_high,
                ),
                _MetaChip(label: d.categoryName, icon: Icons.category_outlined),
                if (d.createdAt != null)
                  _MetaChip(
                    label: _fmtDateTime(d.createdAt!),
                    icon: Icons.schedule_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 22, thickness: 1, color: Colors.orange),
            _kv('지점', d.branchName),
            _kv('주소', d.branchAddress),
            _kv('연락처', d.requesterPhone),
            const Divider(height: 22, thickness: 1, color: Colors.orange),
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

  // ============================================================
  // ✅ 공통 UI 유틸
  // ============================================================
  Widget _oneButton({required String text, required VoidCallback onPressed}) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, -2),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submittingEstimate ? null : onPressed,
            child: Text(_submittingEstimate ? '처리 중...' : text),
          ),
        ),
      ),
    );
  }

  Widget _twoButtons({
    required String leftText,
    required VoidCallback onLeft,
    required String rightText,
    required VoidCallback onRight,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, -2),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(onPressed: onLeft, child: Text(leftText)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onRight,
                  child: Text(rightText),
                ),
              ),
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

  static Widget _kv(String k, String? v, {Color? labelColor}) {
    final value = (v == null || v.isEmpty) ? '-' : v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(fontWeight: FontWeight.w700, color: labelColor),
            ),
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

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  static String _normStatus(String status) => status.trim().toUpperCase();

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

  // ============================================================
  // ✅ HQ/Vendor 액션 핸들러
  // ============================================================
  static void _refreshDetail(WidgetRef ref, int id, AppRole role) {
    ref.invalidate(maintenanceDetailProvider((id: id, role: role)));
  }

  static Future<void> _onHqApproveRequest(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    int id,
  ) async {
    try {
      final res = await MaintenanceDetailApi.hqApproveRequest(id: id);
      if (!context.mounted) return;

      if (res.statusCode == 200) {
        _snack(context, '승인 완료');
        _refreshDetail(ref, id, role);
        return;
      }
      _snack(context, '승인 실패: ${res.statusCode}');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, '승인 실패: $e');
    }
  }

  static Future<void> _onHqApproveEstimate(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    int id,
  ) async {
    try {
      final res = await MaintenanceDetailApi.hqApproveEstimate(id: id);
      if (!context.mounted) return;

      if (res.statusCode == 200) {
        _snack(context, '승인 완료');
        _refreshDetail(ref, id, role);
        return;
      }
      _snack(context, '승인 실패: ${res.statusCode}');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, '승인 실패: $e');
    }
  }

  static Future<void> _onHqRejectRequest(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    int id,
  ) async {
    final reason = await _textDialog(
      context,
      title: '1차 반려 사유 입력',
      hint: '지점 요청 반려 사유를 입력하세요',
      confirmText: '반려',
    );
    if (reason == null || reason.trim().isEmpty) return;

    try {
      final res = await MaintenanceDetailApi.hqRejectRequest(
        id: id,
        reason: reason.trim(),
      );
      if (!context.mounted) return;

      if (res.statusCode == 200) {
        _snack(context, '1차 반려 처리 완료');
        _refreshDetail(ref, id, role);
        return;
      }
      _snack(context, '1차 반려 실패: ${res.statusCode}');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, '1차 반려 실패: $e');
    }
  }

  static Future<void> _onHqRejectEstimate(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    int id,
  ) async {
    final reason = await _textDialog(
      context,
      title: '2차 반려 사유 입력',
      hint: '견적 반려 사유를 입력하세요',
      confirmText: '반려',
    );
    if (reason == null || reason.trim().isEmpty) return;

    try {
      final res = await MaintenanceDetailApi.hqRejectEstimate(
        id: id,
        reason: reason.trim(),
      );
      if (!context.mounted) return;

      if (res.statusCode == 200) {
        _snack(context, '2차 반려 처리 완료');
        _refreshDetail(ref, id, role);
        return;
      }
      _snack(context, '2차 반려 실패: ${res.statusCode}');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, '2차 반려 실패: $e');
    }
  }

  static Future<void> _onCompleteWork(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    int id,
  ) async {
    final dto = await showDialog<_CompleteFormResult>(
      context: context,
      builder: (_) => const _CompleteDialog(),
    );
    if (dto == null) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final res = await MaintenanceDetailApi.completeWork(
      id: id,
      resultComment: dto.comment,
      resultPhotoUrl: dto.photoUrl?.trim().isEmpty == true
          ? null
          : dto.photoUrl?.trim(),
      actualEndDate: dto.completedDate,
    );

    if (!context.mounted) return;

    if (res.statusCode == 200) {
      _snack(context, '작업 완료 제출 완료');
      _refreshDetail(ref, id, role);
    } else {
      _snack(context, '작업 완료 제출 실패: ${res.statusCode}');
    }
  }

  // ✅ 핵심 수정: 컨트롤러를 밖에서 만들고 dispose 하지 말고, 다이얼로그 위젯이 소유/해제
  static Future<String?> _textDialog(
    BuildContext context, {
    required String title,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String confirmText = '확인',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: title,
        hint: hint,
        keyboardType: keyboardType,
        confirmText: confirmText,
      ),
    );
  }
}

// ============================================================
// ✅ 견적 입력 결과
// ============================================================
class _EstimateFormResult {
  final String amount;
  final String comment;
  final DateTime? startDate;
  final DateTime? endDate;

  _EstimateFormResult({
    required this.amount,
    required this.comment,
    this.startDate,
    this.endDate,
  });
}

// ============================================================
// ✅ 견적 입력 다이얼로그 (컨트롤러/포커스 수명은 여기서 책임)
// ============================================================
class _EstimateDialog extends StatefulWidget {
  const _EstimateDialog();

  @override
  State<_EstimateDialog> createState() => _EstimateDialogState();
}

class _EstimateDialogState extends State<_EstimateDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _commentCtrl;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final base = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: base,
      lastDate: DateTime(2100),
      initialDate: _endDate ?? base,
    );
    if (!mounted) return;
    if (picked != null) setState(() => _endDate = picked);
  }

  void _submit() {
    final amount = _amountCtrl.text.trim();
    if (amount.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.of(context).pop(
      _EstimateFormResult(
        amount: amount,
        comment: _commentCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('견적 / 작업일 입력'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '견적 금액',
                hintText: '예: 150000',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '견적 코멘트',
                hintText: '견적 관련 코멘트',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text(
                      _startDate == null ? '작업 시작 예정일' : _fmt(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text(
                      _endDate == null ? '작업 종료 예정일' : _fmt(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('※ 날짜는 선택사항입니다.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop(null);
          },
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('제출')),
      ],
    );
  }
}

// ============================================================
// ✅ 반려 사유 입력 다이얼로그 (컨트롤러 수명 책임)
// ============================================================
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final TextInputType keyboardType;
  final String confirmText;

  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.keyboardType,
    required this.confirmText,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        keyboardType: widget.keyboardType,
        maxLines: 4,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop(null);
          },
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _confirm, child: Text(widget.confirmText)),
      ],
    );
  }
}

// ============================================================
// ✅ Vendor 작업완료 입력 다이얼로그(기존 유지)
// ============================================================
class _CompleteFormResult {
  final String comment;
  final String? photoUrl;
  final DateTime? completedDate;

  _CompleteFormResult({
    required this.comment,
    required this.photoUrl,
    required this.completedDate,
  });
}

class _CompleteDialog extends StatefulWidget {
  const _CompleteDialog();

  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  final _commentCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  DateTime? _completed;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCompleted() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _completed ?? now,
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _completed = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('작업 완료 제출'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '완료 코멘트',
                hintText: '작업 완료 내용을 입력하세요',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _photoCtrl,
              decoration: const InputDecoration(
                labelText: '결과 사진 URL (선택)',
                hintText: '사진 업로드 연결 전 임시',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pickCompleted,
              child: Text(
                _completed == null
                    ? '완료일 선택(선택)'
                    : "${_completed!.year}-${_completed!.month.toString().padLeft(2, '0')}-${_completed!.day.toString().padLeft(2, '0')}",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final c = _commentCtrl.text.trim();
            if (c.isEmpty) return;

            FocusManager.instance.primaryFocus?.unfocus();

            Navigator.pop(
              context,
              _CompleteFormResult(
                comment: c,
                photoUrl: _photoCtrl.text.trim(),
                completedDate: _completed,
              ),
            );
          },
          child: const Text('제출'),
        ),
      ],
    );
  }
}

// ============================================================
// ✅ status 라벨
// ============================================================
String maintenanceStatusLabel(String status) {
  switch (status) {
    case 'REQUESTED':
      return '요청서 제출완료';
    case 'ESTIMATING':
      return '견적중';
    case 'APPROVAL_PENDING':
      return '견적 승인중';
    case 'IN_PROGRESS':
      return '작업중';
    case 'COMPLETED':
      return '작업 완료';
    case 'HQ1_REJECTED':
    case 'HQ2_REJECTED':
    case 'REJECTED':
      return '반려';
    case 'DRAFT':
      return '임시 저장';
    default:
      return status;
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
