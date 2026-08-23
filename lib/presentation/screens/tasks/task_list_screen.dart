import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/task_item.dart';
import '../../providers/member_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../widgets/async_list_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_filter_bar.dart';
import '../../widgets/task_status_sheet.dart';
import '../../widgets/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskListProvider>().loadIfNeeded();
      context.read<MemberProvider>().loadIfNeeded();
      context.read<ProjectListProvider>().loadIfNeeded();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<TaskListProvider>().refresh(),
      context.read<MemberProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskListProvider>();
    final members = context.watch<MemberProvider>();
    final projects = context.watch<ProjectListProvider>();
    final visible = provider.visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: RefreshingIndicator(visible: provider.state.isRefreshing),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-new-task',
        onPressed: () => context.push(Routes.newTask),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: AsyncListView<TaskItem>(
        state: provider.state,
        onRefresh: _refreshAll,
        banner: const TaskFilterBar(),
        empty: EmptyStateView(
          icon: Icons.task_alt_rounded,
          title: 'No tasks yet',
          message: 'Tasks you or your team create will show up here.',
          actionLabel: 'Create a task',
          onAction: () => context.push(Routes.newTask),
        ),
        builder: (context, _) {
          if (visible.isEmpty) {
            return EmptyStateView(
              icon: Icons.filter_alt_off_rounded,
              title: 'No matching tasks',
              message:
                  'No task matches the filters you have applied. Try widening them.',
              actionLabel: 'Clear filters',
              onAction: provider.clearFilter,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              96,
            ),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: Insets.md),
            itemBuilder: (context, index) {
              final task = visible[index];
              return TaskTile(
                task: task,
                assignee: members.userById(task.assigneeId),
                projectName: projects.byId(task.projectId)?.name,
                onTap: () => context.push(Routes.taskDetailOf(task.id)),
                onStatusTap: () => showTaskStatusSheet(
                  context,
                  task: task,
                  onSelected: (status) =>
                      provider.changeStatus(task.id, status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
