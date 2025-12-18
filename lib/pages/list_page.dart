import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';

class ListPage extends ConsumerWidget {
  static const softPink = Color(0xFFFFD1DC);
  static const softPinkBg = Color(0xFFFFE9EE);
  static const blueBtn = Color(0xFF2E66FF);

  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: softPinkBg,
      bottomNavigationBar: const HomeBottomNav(),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('전체 목록'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: softPinkBg,
        foregroundColor: Colors.black,
      ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _ListBody(),
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody();

  @override
  Widget build(BuildContext context) {
    // ✅ TODO: 나중에 서버 API 붙이면 여기만 provider/future로 바꾸면 됨
    final items = _dummyItems()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // ✅ 최신이 위

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final it = items[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // ✅ TODO: 상세 페이지로 이동 원하면 라우트 추가
              // Navigator.pushNamed(context, '/maintenance-detail', arguments: it.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 접수내용
                  Text(
                    it.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _MetaChip(label: it.status, icon: Icons.info_outline),
                      const SizedBox(width: 8),
                      _MetaChip(
                        label: _fmtDate(it.createdAt),
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  static List<_MaintenanceListItem> _dummyItems() {
    return [
      _MaintenanceListItem(
        id: 3,
        title: "에어컨 누수 발생 / 천장 물 떨어짐",
        status: "REQUESTED",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      _MaintenanceListItem(
        id: 2,
        title: "출입문 도어락 작동 불량",
        status: "DRAFT",
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      _MaintenanceListItem(
        id: 1,
        title: "조명 깜빡임 / 전등 교체 요청",
        status: "COMPLETED",
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceListItem {
  final int id;
  final String title; // 접수내용
  final String status; // 상태
  final DateTime createdAt; // 날짜

  _MaintenanceListItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });
}
