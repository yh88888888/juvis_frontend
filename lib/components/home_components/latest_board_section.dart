import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://10.0.2.2:8080";

class BoardItem {
  final int docNo;
  final String content;
  final String status;
  final DateTime? visitDate;

  BoardItem({
    required this.docNo,
    required this.content,
    required this.status,
    required this.visitDate,
  });

  factory BoardItem.fromJson(Map<String, dynamic> json) {
    return BoardItem(
      docNo: json['docNo'],
      content: json['content'],
      status: json['status'],
      visitDate: json['visitDate'] != null
          ? DateTime.parse(json['visitDate'])
          : null,
    );
  }
}

// 🟣 최신 3개 불러오기 위젯
class LatestBoardSection extends StatefulWidget {
  final int userId;

  const LatestBoardSection({super.key, required this.userId});

  @override
  State<LatestBoardSection> createState() => _LatestBoardSectionState();
}

class _LatestBoardSectionState extends State<LatestBoardSection> {
  bool _loading = true;
  String? _error;
  List<BoardItem> _items = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    try {
      final uri = Uri.parse(
        "$apiBase/api/board?userId=${widget.userId}&limit=3",
      );
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('서버 오류');
      }

      final List list = jsonDecode(res.body);
      final boardList = list.map((e) => BoardItem.fromJson(e)).toList();

      setState(() {
        _items = boardList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "데이터를 불러오지 못했습니다";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text("신청된 내역이 없습니다.", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "문서번호: ${item.docNo}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("접수내용: ${item.content}"),
                      Text("상태: ${item.status}"),
                      Text("방문예정일: ${item.visitDate ?? '미정'}"),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // 🔵 점 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (_, __) {
                  int current = 0;
                  if (_pageController.hasClients &&
                      _pageController.page != null) {
                    current = _pageController.page!.round();
                  }

                  final isActive = current == index;

                  return Container(
                    margin: const EdgeInsets.all(6),
                    width: isActive ? 12 : 8,
                    height: isActive ? 12 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
