import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/components/notification/notification_notifier.dart';
import 'package:juvis_faciliry/pages/maintenance_detail_page.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationProvider.notifier).refreshList();
      await ref.read(notificationProvider.notifier).refreshUnreadCount();
      // ✅ 기본 탭: 미읽음
      ref
          .read(notificationProvider.notifier)
          .setFilter(NotificationFilter.unread);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(notificationProvider);
    final items = ref.watch(filteredNotificationsProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: 0, // 0:새메세지, 1:읽음, 2:전체 (기본 미읽음)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('알림'),
          centerTitle: true,
          bottom: TabBar(
            onTap: (idx) {
              final f = switch (idx) {
                0 => NotificationFilter.unread,
                1 => NotificationFilter.read,
                _ => NotificationFilter.all,
              };
              ref.read(notificationProvider.notifier).setFilter(f);
            },
            tabs: const [
              Tab(text: '새메세지'),
              Tab(text: '읽음'),
              Tab(text: '전체'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '새로고침',
              onPressed: () async {
                await ref.read(notificationProvider.notifier).refreshList();
                await ref
                    .read(notificationProvider.notifier)
                    .refreshUnreadCount();
              },
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '전체 읽음',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('전체 읽음 처리'),
                    content: const Text('모든 알림을 읽음으로 처리할까요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;

                final success = await ref
                    .read(notificationProvider.notifier)
                    .markAllRead();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('전체 읽음 처리 실패(서버 오류)')),
                  );
                }
              },
              icon: const Icon(Icons.done_all),
            ),
          ],
        ),
        body: st.loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? Center(
                child: Text(
                  st.filter == NotificationFilter.unread
                      ? '새메세지가 없습니다.'
                      : '알림이 없습니다.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];

                  // ✅ 읽음: 아이콘/글씨 연하게
                  final isRead = n.read;
                  final icon = isRead
                      ? Icons.notifications_none
                      : Icons.notifications;
                  final iconColor = isRead
                      ? Colors.grey.shade400
                      : Colors.black87;
                  final titleColor = isRead ? Colors.black54 : Colors.black87;

                  return Card(
                    child: ListTile(
                      leading: Icon(icon, color: iconColor),
                      title: Text(
                        n.message.isNotEmpty
                            ? n.message
                            : "${n.title}'이 ${n.status} 입니다.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      subtitle: Text(_fmt(n.createdAt)),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaintenanceDetailPage(
                              maintenanceId: n.maintenanceId,
                            ),
                          ),
                        );

                        // ✅ 상세 확인 후 읽음 처리
                        if (!n.read) {
                          final success = await ref
                              .read(notificationProvider.notifier)
                              .markRead(n.id);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('읽음 처리 실패(서버 오류)')),
                            );
                          }
                          // ✅ 미읽음 탭이면 필터가 적용되어 자동으로 목록에서 사라짐
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
