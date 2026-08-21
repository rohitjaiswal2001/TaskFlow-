import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<Result<Snapshot<List<AppNotification>>>> getNotifications({
    CancellationToken? cancelToken,
  });

  Future<Result<AppNotification>> markAsRead(String notificationId);

  Future<Result<void>> markAllAsRead();
}
