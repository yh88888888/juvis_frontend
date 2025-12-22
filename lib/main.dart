import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/maintenance_components/maintenance_category.dart';
import 'package:juvis_faciliry/pages/admin_app_page.dart';
import 'package:juvis_faciliry/pages/admin_page.dart';
import 'package:juvis_faciliry/pages/home_page.dart';
import 'package:juvis_faciliry/pages/list_page.dart';
import 'package:juvis_faciliry/pages/login_page.dart';
import 'package:juvis_faciliry/pages/maintenance_create_page.dart';
import 'package:juvis_faciliry/pages/maintenance_detail_page.dart';

void main() {
  runApp(const ProviderScope(child: JuvisApp()));
}

class JuvisApp extends ConsumerStatefulWidget {
  const JuvisApp({super.key});

  @override
  ConsumerState<JuvisApp> createState() => _JuvisAppState();
}

class _JuvisAppState extends ConsumerState<JuvisApp> {
  bool _bootLoading = true;

  @override
  void initState() {
    debugPrint("initSession START");
    super.initState();

    Future.microtask(() async {
      await ref.read(sessionProvider.notifier).initSession();
      // 여기서 state 보고 라우팅
      if (mounted) {
        setState(() => _bootLoading = false);
      }
    });
    debugPrint("initSession END");
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (_bootLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Pretendard',
          scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        ),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // ✅ 세션 상태에 따라 시작 화면 결정
    Widget startPage;
    if (session == null) {
      startPage = LoginPage();
    } else {
      if (session.role == "BRANCH") {
        startPage = HomePage();
      } else if (session.role == "HQ") {
        startPage = kIsWeb ? AdminPage() : AdminAppPage();
      } else {
        // 혹시 모를 예외
        startPage = LoginPage();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),

      // ✅ initialRoute 대신 home로 시작 화면 제어
      home: startPage,

      // 기존 routes는 그대로 유지 (페이지 이동은 네 방식대로)
      routes: {
        "/login": (context) => LoginPage(),
        "/home": (context) => HomePage(),
        "/admin_web": (context) => AdminPage(),
        "/admin_app": (context) => AdminAppPage(),
        '/list': (_) => const ListPage(),
        '/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return MaintenanceDetailPage(maintenanceId: id);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/maintenance-create') {
          final args = settings.arguments as Map<String, dynamic>;

          final category = args['category'] as MaintenanceCategory;
          final homeHeader =
              args['homeHeader'] as Widget?; // ✅ PreferredSizeWidget? ❌
          final bottomNav = args['bottomNav'] as Widget?;

          return MaterialPageRoute(
            builder: (_) =>
                MaintenanceCreatePage(category: category, bottomNav: bottomNav),
          );
        }

        return null;
      },
    );
  }
}
