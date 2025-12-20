import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/list_components/home_only_bottom_nav.dart';
import 'package:juvis_faciliry/components/list_components/list_provider.dart';

class ListPage extends ConsumerStatefulWidget {
  static const softPink = Color(0xFFFFD1DC);

  // static const softPinkBg = Color(0xFFFFE9EE);
  // static const softPinkBg = Color(0xFFFFFEF6);
  static const softPinkBg = Color(0xFFFFF3F6);

  // static const blueBtn = Color(0xFF2E66FF);
  static const blueBtn = Color(0xFFFFFEF6);

  const ListPage({super.key});

  @override
  ConsumerState<ListPage> createState() => _ListPageState();
}

class _ListPageState extends ConsumerState<ListPage> {
  @override
  void initState() {
    super.initState();

    // ✅ ListPage에 "진입할 때마다" 목록을 다시 가져오게
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(maintenanceListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ListPage.softPinkBg,
      bottomNavigationBar: const HomeOnlyBottomNav(),
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Text.rich(
          TextSpan(
            text: '요청 목록',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF9EB5),
              height: 1.3,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ListPage.softPinkBg,
        foregroundColor: Colors.black,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: ListPage.softPink,
            secondary: ListPage.softPink,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: ListPage.blueBtn,
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
        child: const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _ListBody(),
        ),
      ),
    );
  }
}

class _ListBody extends ConsumerWidget {
  const _ListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(maintenanceListProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('목록 불러오기 실패: $e')),
      data: (items) {
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final it = items[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(context, '/detail', arguments: it.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
      },
    );
  }

  static String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
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
