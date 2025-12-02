import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _StatusHeader(),
            SizedBox(height: 12),
            _KvRow(title: '접수 내용', value: '슬라이딩 도어 고장으로 보수요 청드립니다'),
            SizedBox(height: 6),
            _KvRow(title: '접수 상태', value: '견적 완료'),
            SizedBox(height: 6),
            _KvRow(title: '방문 예정일', value: '-'),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '공사',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '240822-011',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  final String title;
  final String value;

  const _KvRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
