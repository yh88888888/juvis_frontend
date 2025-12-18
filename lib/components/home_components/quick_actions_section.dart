import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/components/home_components/home_bottom_nav.dart';
import 'package:juvis_faciliry/components/home_components/home_header.dart';
import 'package:juvis_faciliry/components/home_components/quick_title.dart';
import 'package:juvis_faciliry/components/maintenance_components/maintenance_category.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  void _goCreatePage(
    BuildContext context,
    MaintenanceCategory category,
    String branchName,
  ) {
    Navigator.pushNamed(
      context,
      '/maintenance-create',
      arguments: {
        'category': category,
        'homeHeader': HomeHeader(name: branchName), // ✅ 인스턴스 + name 주입
        'bottomNav': const HomeBottomNav(), // ✅ 인스턴스
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final branchName = session?.name ?? ''; // 세션 구조에 맞게 조정

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '분야별 접수처',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            QuickTile(
              icon: Icons.electrical_services, // 전기/통신
              label: '전기·통신',
              onTap: () => _goCreatePage(
                context,
                MaintenanceCategory.ELECTRICAL_COMMUNICATION,
                branchName,
              ),
            ),
            QuickTile(
              icon: Icons.lightbulb_outline, // 조명
              label: '조명',
              onTap: () => _goCreatePage(
                context,
                MaintenanceCategory.LIGHTING,
                branchName,
              ),
            ),
            QuickTile(
              icon: Icons.air, // 공조/환기
              label: '공조·환기',
              onTap: () =>
                  _goCreatePage(context, MaintenanceCategory.HVAC, branchName),
            ),
            QuickTile(
              icon: Icons.water_drop, // 급/배수
              label: '급·배수',
              onTap: () => _goCreatePage(
                context,
                MaintenanceCategory.WATER_SUPPLY_DRAINAGE,
                branchName,
              ),
            ),
            QuickTile(
              icon: Icons.health_and_safety, // 안전/위생
              label: '안전·위생',
              onTap: () => _goCreatePage(
                context,
                MaintenanceCategory.SAFETY_HYGIENE,
                branchName,
              ),
            ),
            QuickTile(
              icon: Icons.more_horiz, // 기타
              label: '기타',
              onTap: () =>
                  _goCreatePage(context, MaintenanceCategory.ETC, branchName),
            ),
          ],
        ),
      ],
    );
  }
}
