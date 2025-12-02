import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String name;

  const HomeHeader({required this.name, super.key});

  static const softPinkBg = Color(0xFFFFE9EE);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: '쥬비스다이어트 ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF9EB5),
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: '$name\n',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const TextSpan(
                  text: '🔧 설비 유지 관리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: softPinkBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.apartment, color: Colors.black54),
        ),
      ],
    );
  }
}
