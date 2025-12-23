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
import 'package:juvis_faciliry/pages/notification_page.dart';
import 'package:juvis_faciliry/pages/vendor_list_page.dart';
import 'package:juvis_faciliry/pages/vendor_page.dart';

// ✅ 전역 RouteObserver (AdminAppPage에서 "돌아왔을 때" 감지)
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
    super.initState();

    Future.microtask(() async {
      await ref.read(sessionProvider.notifier).initSession();
      if (mounted) setState(() => _bootLoading = false);
    });
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

    Widget startPage;
    if (session == null) {
      startPage = LoginPage();
    } else if (session.role == "BRANCH") {
      startPage = const HomePage();
    } else if (session.role == "HQ") {
      startPage = kIsWeb ? const AdminPage() : const AdminAppPage();
    } else if (session.role == "VENDOR") {
      startPage = const VendorPage();
    } else {
      startPage = LoginPage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),

      // ✅ 여기! observer 연결
      navigatorObservers: [routeObserver],

      home: startPage,
      routes: {
        "/login": (_) => LoginPage(),
        "/home": (_) => const HomePage(),
        "/admin_web": (_) => const AdminPage(),
        "/admin_app": (_) => const AdminAppPage(),
        "/list": (_) => const ListPage(),
        "/vendor": (_) => const VendorPage(),
        "/vendor-list": (_) => const VendorListPage(),
        "/notifications": (_) => const NotificationsPage(),
        "/detail": (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return MaintenanceDetailPage(maintenanceId: id);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/maintenance-create') {
          final args = settings.arguments as Map<String, dynamic>;
          final category = args['category'] as MaintenanceCategory;
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
