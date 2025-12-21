import 'package:flutter/material.dart';

class ImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImageViewerPage> createState() => ImageViewerPageState();
}

class ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        itemBuilder: (_, index) {
          return InteractiveViewer(
            child: Center(child: Image.network(widget.imageUrls[index])),
          );
        },
      ),
    );
  }
}
