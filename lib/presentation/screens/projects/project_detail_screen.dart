import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/task_item.dart';
import '../../../domain/entities/task_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/project_detail_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../state/view_state.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/responsive.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_filter_bar.dart';
import '../../widgets/task_status_sheet.dart';
import '../../widgets/task_summary_card.dart';
import '../../widgets/task_tile.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectDetailProvider>().loadIfNeeded();
      context.read<TaskListProvider>().loadIfNeeded();
      context.read<MemberProvider>().loadIfNeeded();
    });
  }

  Future<void> _pushAndRefreshTasks(String location) async {
    await context.push(location);
    if (!mounted) return;
    await context.read<TaskListProvider>().refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProjectDetailProvider>().refresh(),
      context.read<TaskListProvider>().refresh(),
    ]);
  }

  Future<void> _confirmDelete(Project project) async {
    final projects = context.read<ProjectListProvider>();
    final router = GoRouter.of(context);

    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Delete "${project.name}"?',
      message: 'The project and all of its tasks will be removed.',
    );
    if (!confirmed || !mounted) return;

    final result = await projects.delete(project.id);
    if (!mounted) return;

    result.fold((_) {
      AppFeedback.success(context, 'Project deleted');
      if (router.canPop()) router.pop();
    }, (failure) => AppFeedback.error(context, failure));
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<ProjectDetailProvider>();
    final tasks = context.watch<TaskListProvider>();
    final members = context.watch<MemberProvider>();
    final isAdmin = context.select<AuthProvider, bool>((auth) => auth.isAdmin);

    final project = detail.value;
    final summary = TaskSummary.from(tasks.items);
    final visible = tasks.visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Project'),
        actions: [
          if (project != null && isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Project actions',
              onSelected: (value) {
                if (value == 'edit') {
                  context.push(Routes.projectEditOf(project.id));
                } else {
                  _confirmDelete(project);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit project')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete project',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: RefreshingIndicator(
            visible: detail.state.isRefreshing || tasks.state.isRefreshing,
          ),
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab-add-task',
              onPressed: () =>
                  _pushAndRefreshTasks(Routes.newTaskIn(project.id)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add task'),
            ),
      body: _buildBody(context, project, summary, visible, tasks, members),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Project? project,
    TaskSummary summary,
    List<TaskItem> visible,
    TaskListProvider tasks,
    MemberProvider members,
  ) {
    if (project == null) {
      return switch (context.watch<ProjectDetailProvider>().state) {
        ErrorState(:final failure) => ErrorStateView(
          failure: failure,
          onRetry: _refresh,
        ),
        _ => const Padding(
          padding: EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 200, height: 22),
              SizedBox(height: Insets.lg),
              SkeletonCard(lines: 3),
            ],
          ),
        ),
      };
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, 96),
        children: [
          if (tasks.state.hasStaleData)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: StaleDataBanner(
                fetchedAt: tasks.state.fetchedAt,
                onRetry: _refresh,
              ),
            ),
          _ProjectHeader(project: project),
          const SizedBox(height: Insets.md),
          TaskSummaryCard(
            summary: summary,
            selectedStatus: tasks.filter.statuses.length == 1
                ? tasks.filter.statuses.first
                : null,
            onStatusTap: (status) =>
                tasks.setFilter(tasks.filter.toggleStatus(status)),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(
            title: 'Tasks',
            subtitle: tasks.filter.isActive
                ? '${visible.length} of ${tasks.items.length} shown'
                : '${tasks.items.length} in this project',
            action: const TaskFilterBar(showSearch: false),
          ),
          ..._buildTaskSection(context, tasks, members, visible),
        ],
      ),
    );
  }

  List<Widget> _buildTaskSection(
    BuildContext context,
    TaskListProvider tasks,
    MemberProvider members,
    List<TaskItem> visible,
  ) {
    if (tasks.items.isEmpty) {
      return [
        switch (tasks.state) {
          InitialState() || LoadingState() => const Column(
            children: [
              SkeletonCard(),
              SizedBox(height: Insets.md),
              SkeletonCard(),
            ],
          ),
          ErrorState(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => tasks.refresh(),
          ),
          _ => EmptyStateView(
            icon: Icons.playlist_add_rounded,
            title: 'No tasks in this project',
            message: 'Add the first task and assign it to someone on the team.',
            actionLabel: 'Add task',
            onAction: () => _pushAndRefreshTasks(
              Routes.newTaskIn(context.read<ProjectDetailProvider>().projectId),
            ),
          ),
        },
      ];
    }

    if (visible.isEmpty) {
      return [
        EmptyStateView(
          icon: Icons.filter_alt_off_rounded,
          title: 'No matching tasks',
          message: 'Nothing in this project matches the current filters.',
          actionLabel: 'Clear filters',
          onAction: tasks.clearFilter,
        ),
      ];
    }

    return [
      for (final task in visible) ...[
        TaskTile(
          task: task,
          assignee: members.userById(task.assigneeId),
          onTap: () => _pushAndRefreshTasks(Routes.taskDetailOf(task.id)),
          onStatusTap: () => showTaskStatusSheet(
            context,
            task: task,
            onSelected: (status) => tasks.changeStatus(task.id, status),
          ),
        ),
        const SizedBox(height: Insets.md),
      ],
    ];
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(project.name, style: theme.textTheme.titleLarge),
                ),
                Chip(
                  label: Text(project.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Text(
              project.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.md),
            Text(
              'Created ${Dates.formatTimestamp(project.createdAt)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
