import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local/cache_store.dart';
import '../datasources/remote/api_call_runner.dart';
import '../datasources/remote/taskflow_api.dart';
import '../models/notification_model.dart';
import '../session/session_manager.dart';
import 'cache_fallback.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required TaskFlowApi remoteApi,
    required ApiCallRunner callRunner,
    required SessionManager sessionManager,
    required CacheFallback cacheFallback,
  }) : _api = remoteApi,
       _run = callRunner,
       _session = sessionManager,
       _cache = cacheFallback;

  final TaskFlowApi _api;
  final ApiCallRunner _run;
  final SessionManager _session;
  final CacheFallback _cache;

  @override
  Future<Result<Snapshot<List<AppNotification>>>> getNotifications({
    CancellationToken? cancelToken,
  }) {
    final session = _session.requireCurrent;

    return _cache.load<AppNotification, NotificationModel>(
      key: CacheKeys.notifications(session.user.id),
      fetch: () async {
        final response = await _run.run(
          () => _api.getNotifications(cancelToken: cancelToken),
        );
        return response.data;
      },
      encode: (model) => model.toJson(),
      decode: NotificationModel.fromJson,
      toEntity: (model) => model.toEntity(),
    );
  }

  @override
  Future<Result<AppNotification>> markAsRead(String notificationId) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.markNotificationRead(notificationId),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<void>> markAllAsRead() {
    return Result.guard(() => _run.run(() => _api.markAllNotificationsRead()));
  }
}
