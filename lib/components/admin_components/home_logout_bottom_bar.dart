import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/notification/notification_notifier.dart'; // ✅ 추가
import 'package:juvis_faciliry/pages/login_page.dart';

class HomeLogoutBottomBar extends ConsumerStatefulWidget {
  const HomeLogoutBottomBar({super.key});

  @override
  ConsumerState<HomeLogoutBottomBar> createState() =>
      _HomeLogoutBottomBarState();
}

class _HomeLogoutBottomBarState extends ConsumerState<HomeLogoutBottomBar> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationProvider.notifier).refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider); // ✅ 뱃지 숫자 연동

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // =====================
            // 홈 버튼
            // =====================
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text(
                  '홈',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/admin_app',
                    (route) => false,
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // =====================
            // 알림 버튼 (뱃지)
            // =====================
            Expanded(
              child: OutlinedButton.icon(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                label: const Text(
                  '알림',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // ✅ 알림 진입 시 최신 unread 당겨오기 (지점쪽과 동일)
                  await ref
                      .read(notificationProvider.notifier)
                      .refreshUnreadCount();

                  if (!context.mounted) return;

                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            ),

            const SizedBox(width: 12),

            // =====================
            // 로그아웃 버튼
            // =====================
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.logout_outlined),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => _handleLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ 알림 상태도 같이 초기화(지점쪽과 동일한 처리)
    ref.read(notificationProvider.notifier).clear();

    // ✅ 세션 제거
    await ref.read(sessionProvider.notifier).logout();

    // ✅ 로그인 페이지로 완전 이동
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
