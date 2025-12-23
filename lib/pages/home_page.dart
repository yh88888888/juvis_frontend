import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';
import 'package:juvis_faciliry/components/home_components/home_header.dart';
import 'package:juvis_faciliry/components/home_components/latest_board_section.dart';
import 'package:juvis_faciliry/components/home_components/quick_actions_section.dart';
import 'package:juvis_faciliry/components/notification/notification_notifier.dart';

class HomePage extends ConsumerStatefulWidget {
  static const softPink = Color(0xFFFFD1DC);
  static const softPinkBg = Color(0xFFFFE9EE);
  static const blueBtn = Color(0xFF2E66FF);

  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();

    // ✅ 홈 진입 시 알림 뱃지 갱신 (1회)
    Future.microtask(() {
      ref.read(notificationProvider.notifier).refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = ref.watch(sessionProvider);

    // ✅ 세션 없으면 로그인으로 이동 (build 중 직접 push 금지)
    if (sessionUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String name = sessionUser.name ?? '본사';

    return Scaffold(
      backgroundColor: HomePage.softPinkBg,
      bottomNavigationBar: const HomeBottomNav(),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: HomePage.softPink,
            secondary: HomePage.softPink,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: HomePage.blueBtn,
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
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              // 🔹 상단 헤더
              HomeHeader(name: name),

              const SizedBox(height: 40),

              // 🔹 최신 현황 카드
              const SizedBox(height: 200, child: LatestBoardSection()),

              const SizedBox(height: 18),

              // 🔹 전체 목록 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/list');
                  },
                  child: const Text(
                    '요청서 전체보기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 🔹 빠른 액션
              const QuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
