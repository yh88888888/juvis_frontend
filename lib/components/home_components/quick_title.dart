import 'package:flutter/material.dart';

class QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap; // ✅ 추가

  const QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap, // ✅ 추가
  });

  static const Color tileBg = Color(0xFFFFF3F6);
  static const Color iconTint = Color(0xFFFFB6C1);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // ✅ 기존 onTap: () {} 제거
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconTint),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
