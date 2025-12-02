import 'package:flutter/material.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';
import 'package:juvis_faciliry/components/home_components/home_header.dart';
import 'package:juvis_faciliry/components/home_components/latest_board_section.dart';
import 'package:juvis_faciliry/components/home_components/quick_actions_section.dart';
import 'package:juvis_faciliry/components/home_components/status_card.dart';

class HomePage extends StatelessWidget {
  static const softPink = Color(0xFFFFD1DC);
  static const softPinkBg = Color(0xFFFFE9EE);
  static const blueBtn = Color(0xFF2E66FF);

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String name = args['name'] ?? '이름 없음';
    final int userId = args['userId']; // 절대 null 이라고 가정!

    return Scaffold(
      bottomNavigationBar: const HomeBottomNav(),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: softPink,
            secondary: softPink,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: blueBtn,
              foregroundColor: Colors.white,
              minimumSize: const Size(340, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              HomeHeader(name: name),
              const SizedBox(height: 16),
              const StatusCard(),
              const SizedBox(height: 12),
              LatestBoardSection(userId: userId), // ! 로 non-null 보장
              const SizedBox(height: 16),
              Center(
                child: TextButton(onPressed: () {}, child: const Text('더보기')),
              ),
              const SizedBox(height: 18),
              const QuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
