import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/pages/login_page.dart';

class HomeBottomNav extends ConsumerStatefulWidget {
  const HomeBottomNav({super.key});

  @override
  ConsumerState<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends ConsumerState<HomeBottomNav> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      indicatorColor: Colors.transparent, // 홈버튼 테두리 없애기
      onDestinationSelected: (index) async {
        if (index == 3) {
          await _handleLogout();
          return;
        }

        if (index == 1) {
          Navigator.pushNamed(context, '/maintenance-list');
          return;
        }

        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }

        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
        NavigationDestination(icon: Icon(Icons.build_outlined), label: '접수내역'),
        NavigationDestination(
          icon: Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_outlined),
          ),
          label: '알림',
        ),
        NavigationDestination(icon: Icon(Icons.logout_outlined), label: '로그아웃'),
      ],
    );
  }

  Future<void> _handleLogout() async {
    // ✅ 다이얼로그는 "현재 context"로 띄우되,
    // pop은 dialogContext로 처리하는 게 안전
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

    // ✅ 세션 제거
    await ref.read(sessionProvider.notifier).logout();

    if (!mounted) return;

    // ✅ 네비게이션 바/중첩 네비게이터 구조에서 더 확실하게 루트 네비게이터로 이동
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      // LoginPage가 const 생성자면 OK
      (_) => false,
    );
  }
}
