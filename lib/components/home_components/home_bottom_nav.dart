import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
        NavigationDestination(icon: Icon(Icons.build_outlined), label: '접수내역'),
        NavigationDestination(
          icon: Badge(
            label: Text('3'), //TODO: 확인되지 않은 알림수 연동
            child: Icon(Icons.notifications_outlined),
          ),
          label: '알림',
        ),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
      ],
    );
  }
}
