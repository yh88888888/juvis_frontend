import 'package:flutter/material.dart';
import 'package:juvis_faciliry/components/home_components/quick_title.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 접수',
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
          children: const [
            QuickTile(icon: Icons.bolt, label: '전기/통신'),
            QuickTile(icon: Icons.grid_on, label: '유리'),
            QuickTile(icon: Icons.lightbulb_outline, label: '등기구'),
            QuickTile(icon: Icons.local_fire_department, label: '소방'),
            QuickTile(icon: Icons.table_bar, label: '간판'),
            QuickTile(icon: Icons.grid_4x4, label: '타일'),
          ],
        ),
      ],
    );
  }
}
