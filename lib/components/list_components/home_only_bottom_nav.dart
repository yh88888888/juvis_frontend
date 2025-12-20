import 'package:flutter/material.dart';

class HomeOnlyBottomNav extends StatelessWidget {
  const HomeOnlyBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BottomAppBar(
        child: SizedBox(
          height: 56,
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.home_outlined, size: 26),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              tooltip: '홈',
            ),
          ),
        ),
      ),
    );
  }
}
