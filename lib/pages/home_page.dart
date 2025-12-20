import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';
import 'package:juvis_faciliry/components/home_components/home_header.dart';
import 'package:juvis_faciliry/components/home_components/latest_board_section.dart';
import 'package:juvis_faciliry/components/home_components/quick_actions_section.dart';

class HomePage extends ConsumerWidget {
  static const softPink = Color(0xFFFFD1DC);
  static const softPinkBg = Color(0xFFFFE9EE);

  // static const blueBtn = Color(0xFFFFFEF6);
  static const blueBtn = Color(0xFF2E66FF);

  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionUser = ref.watch(sessionProvider);
    // 세션이 없으면(로그아웃/토큰만료 등) 로그인 화면으로 보내거나 로딩 처리

    if (sessionUser == null) {
      // main에서 session==null이면 LoginPage로 가게 되어있으면
      // 여기선 로딩만 보여줘도 충분함
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String name = sessionUser.name;

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
              const SizedBox(height: 40),

              const SizedBox(
                height: 200, // ✅ 너 카드 실제 높이에 맞춰 조절 (예: 160~200)
                child: LatestBoardSection(),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/list', // 새로 만들 목록 페이지 라우트
                    );
                  },
                  child: const Text('전체 목록 보기'),
                ),
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
