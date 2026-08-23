import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../state/async_list_notifier.dart';

class NotificationProvider extends AsyncListNotifier<AppNotification>
    with SessionAwareNotifier<AppNotification> {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<Snapshot<List<AppNotification>>>> fetch(
    CancellationToken cancelToken,
  ) {
    return _repository.getNotifications(cancelToken: cancelToken);
  }

  int get unreadCount => items.where((item) => !item.isRead).length;

  Future<void> markAsRead(String notificationId) async {
    final result = await _repository.markAsRead(notificationId);

    result.fold((updated) {
      final index = items.indexWhere((item) => item.id == updated.id);
      if (index == -1) return;
      replaceItems([...items]..[index] = updated);
    }, (_) {});
  }

  Future<void> markAllAsRead() async {
    final result = await _repository.markAllAsRead();
    if (result.isOk) {
      replaceItems(items.map((item) => item.markRead()).toList());
    }
  }
}
