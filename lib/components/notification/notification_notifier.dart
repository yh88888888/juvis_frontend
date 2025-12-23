import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juvis_faciliry/_core/util/resp.dart';
import 'package:juvis_faciliry/components/notification/app_notification_model.dart';

import 'notification_api.dart';

enum NotificationFilter { all, unread, read }

class NotificationState {
  final List<AppNotification> items; // 서버에서 받은 "전체" 목록(읽음/미읽음 포함)
  final int unreadCount;
  final bool loading;
  final NotificationFilter filter;

  const NotificationState({
    required this.items,
    required this.unreadCount,
    required this.loading,
    required this.filter,
  });

  NotificationState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? loading,
    NotificationFilter? filter,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      filter: filter ?? this.filter,
    );
  }

  static const empty = NotificationState(
    items: [],
    unreadCount: 0,
    loading: false,
    filter: NotificationFilter.unread, // ✅ 기본: 미읽음
  );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState.empty);

  void setFilter(NotificationFilter f) {
    state = state.copyWith(filter: f);
  }

  Future<void> refreshUnreadCount() async {
    final res = await NotificationApi.fetchUnreadCount();
    if (res.statusCode != 200) return;

    final wrapper = Resp.fromBody(res.body);
    if (!wrapper.ok) return;

    final n = (wrapper.body as num?)?.toInt() ?? 0;
    state = state.copyWith(unreadCount: n);
  }

  Future<void> refreshList() async {
    state = state.copyWith(loading: true);

    try {
      final res = await NotificationApi.fetchList();
      if (res.statusCode != 200) {
        state = state.copyWith(loading: false);
        return;
      }

      final wrapper = Resp.fromBody(res.body);
      if (!wrapper.ok || wrapper.body == null || wrapper.body is! List) {
        state = state.copyWith(loading: false);
        return;
      }

      final list = (wrapper.body as List)
          .whereType<Map>()
          .map((m) => AppNotification.fromJson(m.cast<String, dynamic>()))
          .toList();

      final unread = list.where((e) => !e.read).length;
      state = state.copyWith(items: list, unreadCount: unread, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// ✅ 단건 읽음 (읽은 뒤 "미읽음 탭"에서는 자동으로 사라지게 됨)
  Future<bool> markRead(int notificationId) async {
    final res = await NotificationApi.markRead(notificationId);
    if (res.statusCode != 200) return false;

    final wrapper = Resp.fromBody(res.body);
    if (!wrapper.ok) return false;

    // 로컬 즉시 반영(전체 목록에선 남고, 미읽음 필터에선 자동 제외됨)
    final nextItems = state.items
        .map((n) => n.id == notificationId ? n.copyWith(read: true) : n)
        .toList();

    final unread = nextItems.where((e) => !e.read).length;
    state = state.copyWith(items: nextItems, unreadCount: unread);

    // 서버 unread-count 동기화(선택)
    await refreshUnreadCount();
    return true;
  }

  Future<bool> markAllRead() async {
    // UX 즉시 반영
    final nextItems = state.items
        .map((n) => n.read ? n : n.copyWith(read: true))
        .toList();
    state = state.copyWith(items: nextItems, unreadCount: 0);

    final res = await NotificationApi.markAllRead();
    if (res.statusCode != 200) return false;

    final wrapper = Resp.fromBody(res.body);
    if (!wrapper.ok) return false;

    await refreshUnreadCount();
    return true;
  }

  void clear() => state = NotificationState.empty;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (ref) => NotificationNotifier(),
    );

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// ✅ 화면에 보여줄 목록(필터 적용 결과)
final filteredNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final st = ref.watch(notificationProvider);

  final f = st.filter ?? NotificationFilter.unread; // ✅ 방어
  final items = st.items;

  switch (f) {
    case NotificationFilter.all:
      return items;
    case NotificationFilter.unread:
      return items.where((e) => !e.read).toList();
    case NotificationFilter.read:
      return items.where((e) => e.read).toList();
  }
});
