import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/notification/notification_notifier.dart';

class HomeBottomNav extends ConsumerStatefulWidget {
  const HomeBottomNav({super.key});

  @override
  ConsumerState<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends ConsumerState<HomeBottomNav> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationProvider.notifier).refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(unreadCountProvider);

    // ✅ 세션 role 읽어서 홈 라우트 결정
    final session = ref.watch(sessionProvider);
    final roleStr = (session?.role?.toString() ?? '').toUpperCase();
    final isVendor = roleStr.contains('VENDOR');

    // ✅ vendor면 VendorPage로 (라우트명 프로젝트에 맞게!)
    final String homeRoute = isVendor ? '/vendor' : '/home';

    return NavigationBar(
      selectedIndex: _selectedIndex,
      indicatorColor: Colors.transparent,
      onDestinationSelected: (index) async {
        if (index == 3) {
          await _handleLogout();
          return;
        }

        if (index == 2) {
          await ref.read(notificationProvider.notifier).refreshUnreadCount();
          if (!mounted) return;
          Navigator.pushNamed(context, '/notifications');
          setState(() => _selectedIndex = index);
          return;
        }

        if (index == 1) {
          Navigator.pushNamed(context, '/list');
          setState(() => _selectedIndex = index);
          return;
        }

        if (index == 0) {
          // ✅ 핵심: 홈 버튼 목적지 분기
          Navigator.pushNamedAndRemoveUntil(
            context,
            homeRoute,
            (route) => false,
          );
          setState(() => _selectedIndex = index);
          return;
        }

        setState(() => _selectedIndex = index);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: '홈',
        ),
        const NavigationDestination(
          icon: Icon(Icons.build_outlined),
          label: '접수내역',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
          label: '알림',
        ),
        const NavigationDestination(
          icon: Icon(Icons.logout_outlined),
          label: '로그아웃',
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
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
    ref.read(notificationProvider.notifier).clear();
    await ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
