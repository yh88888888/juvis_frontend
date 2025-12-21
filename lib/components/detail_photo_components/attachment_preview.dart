import 'package:flutter/material.dart';
import 'package:juvis_faciliry/components/detail_photo_components/image_viewer_page.dart';

class AttachmentPreview extends StatelessWidget {
  final List<String> imageUrls;

  const AttachmentPreview({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const Text('첨부된 사진이 없습니다.');
    }

    final preview = imageUrls.take(3).toList();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: preview.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = preview[index];
          return GestureDetector(
            onTap: () {
              _openImageViewer(context, imageUrls, index);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImageViewerPage(imageUrls: urls, initialIndex: initialIndex),
      ),
    );
  }
}
