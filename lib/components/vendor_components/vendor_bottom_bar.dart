import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/pages/login_page.dart';

class VendorBottomBar extends ConsumerStatefulWidget {
  const VendorBottomBar({super.key});

  @override
  ConsumerState<VendorBottomBar> createState() => _VendorBottomBarState();
}

class _VendorBottomBarState extends ConsumerState<VendorBottomBar> {
  int _selectedIndex = 0;

  Future<void> _handleLogout(BuildContext context) async {
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

    await ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      indicatorColor: Colors.transparent,
      onDestinationSelected: (index) async {
        setState(() => _selectedIndex = index);

        if (index == 0) {
          // ✅ vendor 홈
          Navigator.pushNamedAndRemoveUntil(context, '/vendor', (r) => false);
          return;
        }
        if (index == 1) {
          // ✅ vendor 목록
          Navigator.pushNamed(context, '/vendor-list');
          return;
        }
        if (index == 2) {
          await _handleLogout(context);
          return;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
        NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: '목록'),
        NavigationDestination(icon: Icon(Icons.logout_outlined), label: '로그아웃'),
      ],
    );
  }
}
