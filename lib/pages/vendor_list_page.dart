import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_lilst_model.dart';
import 'package:juvis_faciliry/components/vendor_components/vendor_list_provider.dart';

class VendorListPage extends ConsumerStatefulWidget {
  const VendorListPage({super.key});

  @override
  ConsumerState<VendorListPage> createState() => _VendorRequestListPageState();
}

class _VendorRequestListPageState extends ConsumerState<VendorListPage> {
  String? _status; // null이면 전체

  // 서버 status 값 맞춰서 수정
  static const statusOptions = <String?>[
    null,
    'ESTIMATING',
    'APPROVAL_PENDING',
    'IN_PROGRESS',
    'COMPLETED',
  ];

  String _label(String? v) {
    return switch (v) {
      null => '전체',
      'ESTIMATING' => '견적 제출 필요',
      'APPROVAL_PENDING' => '본사 승인 대기',
      'IN_PROGRESS' => '작업 중',
      'COMPLETED' => '완료',
      _ => v,
    };
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(
      vendorListProvider(VendorListQuery(status: _status)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('요청 목록'), centerTitle: true),
      body: Column(
        children: [
          // ✅ 필터 바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('상태'),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _status,
                  items: statusOptions
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v, child: Text(_label(v))),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _status = v);
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: () {
                    ref.invalidate(
                      vendorListProvider(VendorListQuery(status: _status)),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ✅ 리스트
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('목록 불러오기 실패: $e'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('데이터가 없습니다.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      vendorListProvider(VendorListQuery(status: _status)),
                    );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return _ItemCard(it: it);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final VendorListItem it;

  const _ItemCard({required this.it});

  @override
  Widget build(BuildContext context) {
    final created = it.createdAt?.toString().split('.').first ?? '-';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: vendor 상세 페이지 라우트로 연결
          // Navigator.pushNamed(context, '/vendor/detail', arguments: it.id);
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip('상태', it.status),
                  if (it.branchName != null) _chip('지점', it.branchName!),
                  if (it.category != null) _chip('카테고리', it.category!),
                ],
              ),
              const SizedBox(height: 10),
              Text('생성: $created', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text('$k: $v', style: const TextStyle(fontSize: 12)),
    );
  }
}
