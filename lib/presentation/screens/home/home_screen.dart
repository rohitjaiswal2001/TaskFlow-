import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/task_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../widgets/project_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_status_sheet.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final members = context.read<MemberProvider>();
    await Future.wait([
      context.read<ProjectListProvider>().loadIfNeeded(),
      context.read<TaskListProvider>().loadIfNeeded(),
      context.read<NotificationProvider>().loadIfNeeded(),
      members.loadIfNeeded(),

      members.loadOrganizationIfNeeded(),
    ]);
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProjectListProvider>().refresh(),
      context.read<TaskListProvider>().refresh(),
      context.read<NotificationProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final members = context.watch<MemberProvider>();
    final projects = context.watch<ProjectListProvider>();
    final tasks = context.watch<TaskListProvider>();
    final notifications = context.watch<NotificationProvider>();

    final user = auth.session?.user;
    final myTasks =
        tasks.items
            .where(
              (task) => task.assigneeId == user?.id && !task.status.isClosed,
            )
            .toList()
          ..sort(_byDueDate);
    final overdue = tasks.items.where((task) => task.isOverdue()).length;
    final loading = tasks.state.isLoading && !tasks.hasLoadedOnce;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Insets.lg,
        title: Row(
          children: [
            UserAvatar(user: user, size: 36),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(user?.name),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    members.organization?.name ?? 'Loading workspace…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: notifications.unreadCount > 0,
            label: Text('${notifications.unreadCount}'),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push(Routes.notifications),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: Insets.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: RefreshingIndicator(visible: tasks.state.isRefreshing),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.lg,
            Insets.lg,
            Insets.xxl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Assigned to you',
                    value: '${myTasks.length}',
                    icon: Icons.assignment_ind_outlined,
                    loading: loading,
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: _StatTile(
                    label: 'Overdue',
                    value: '$overdue',
                    icon: Icons.event_busy_outlined,
                    highlight: overdue > 0,
                    loading: loading,
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: _StatTile(
                    label: 'Projects',
                    value: '${projects.items.length}',
                    icon: Icons.folder_outlined,
                    loading:
                        projects.state.isLoading && !projects.hasLoadedOnce,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xl),

            SectionHeader(
              title: 'Your tasks',
              subtitle: myTasks.isEmpty ? null : 'Sorted by due date',
              action: TextButton(
                onPressed: () => context.go(Routes.tasks),
                child: const Text('See all'),
              ),
            ),
            if (loading)
              const SkeletonCard()
            else if (myTasks.isEmpty)
              _QuietCard(
                icon: Icons.beach_access_outlined,
                message: 'Nothing is assigned to you right now.',
              )
            else
              for (final task in myTasks.take(4)) ...[
                TaskTile(
                  task: task,
                  assignee: members.userById(task.assigneeId),
                  projectName: projects.byId(task.projectId)?.name,
                  onTap: () => context.push(Routes.taskDetailOf(task.id)),
                  onStatusTap: () => showTaskStatusSheet(
                    context,
                    task: task,
                    onSelected: (status) => tasks.changeStatus(task.id, status),
                  ),
                ),
                const SizedBox(height: Insets.md),
              ],

            const SizedBox(height: Insets.lg),
            SectionHeader(
              title: 'Projects',
              action: TextButton(
                onPressed: () => context.go(Routes.projects),
                child: const Text('See all'),
              ),
            ),
            if (projects.state.isLoading && !projects.hasLoadedOnce)
              const SkeletonCard()
            else if (projects.items.isEmpty)
              _QuietCard(
                icon: Icons.folder_off_outlined,
                message: 'No projects in this organization yet.',
              )
            else
              for (final project in projects.items.take(3)) ...[
                ProjectCard(
                  project: project,
                  onTap: () => context.push(Routes.projectDetailOf(project.id)),
                ),
                const SizedBox(height: Insets.md),
              ],
          ],
        ),
      ),
    );
  }

  static int _byDueDate(TaskItem a, TaskItem b) {
    final left = a.dueDate;
    final right = b.dueDate;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  static String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    if (name == null) return part;
    return '$part, ${name.split(' ').first}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.loading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: Insets.sm),
            if (loading)
              const SkeletonBox(width: 28, height: 24)
            else
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(color: color),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
