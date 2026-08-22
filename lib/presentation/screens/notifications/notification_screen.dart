import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/entities/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/async_list_view.dart';
import '../../widgets/state_views.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().loadIfNeeded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: RefreshingIndicator(visible: provider.state.isRefreshing),
        ),
      ),
      body: AsyncListView<AppNotification>(
        state: provider.state,
        onRefresh: provider.refresh,
        empty: const EmptyStateView(
          icon: Icons.notifications_off_outlined,
          title: 'Nothing new',
          message: 'Assignments and task updates meant for you will land here.',
        ),
        builder: (context, notifications) => ListView.separated(
          padding: const EdgeInsets.all(Insets.lg),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _NotificationTile(
              notification: notification,
              onTap: () {
                provider.markAsRead(notification.id);
                final taskId = notification.taskId;
                if (taskId != null) context.push(Routes.taskDetailOf(taskId));
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.xs,
        ),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(
              alpha: unread ? 0.16 : 0.06,
            ),
          ),
          child: Icon(
            Icons.assignment_ind_outlined,
            size: 19,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          notification.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            Dates.relative(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: unread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}
