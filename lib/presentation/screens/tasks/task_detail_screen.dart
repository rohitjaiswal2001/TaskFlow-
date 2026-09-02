import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/entities/task_comment.dart';
import '../../../domain/entities/task_item.dart';
import '../../providers/member_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_detail_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../state/view_state.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/assignee_picker_sheet.dart';
import '../../widgets/responsive.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/task_status_sheet.dart';
import '../../widgets/user_avatar.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskDetailProvider>().loadIfNeeded();
      context.read<MemberProvider>().loadIfNeeded();
      context.read<ProjectListProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _syncToList(TaskItem task) {
    context.read<TaskListProvider>().applyLocalUpdate(task);
  }

  Future<void> _changeAssignee(TaskItem task) async {
    final detail = context.read<TaskDetailProvider>();
    final members = context.read<MemberProvider>();
    await members.loadIfNeeded();
    if (!mounted) return;

    final choice = await showModalBottomSheet<AssigneeChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssigneePickerSheet(
        state: members.state,
        currentAssigneeId: task.assigneeId,
        onRetry: members.refresh,
      ),
    );

    if (choice == null || !mounted) return;

    final result = choice.isUnassign
        ? await detail.unassign()
        : await detail.assign(choice.userId!);
    if (!mounted) return;

    result.fold((updated) {
      _syncToList(updated);
      AppFeedback.success(
        context,
        choice.isUnassign ? 'Assignee removed' : 'Task assigned',
      );
    }, (failure) => AppFeedback.error(context, failure));
  }

  Future<void> _delete(TaskItem task) async {
    final detail = context.read<TaskDetailProvider>();
    final list = context.read<TaskListProvider>();
    final router = GoRouter.of(context);

    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Delete this task?',
      message: '"${task.title}" will be removed for everyone.',
    );
    if (!confirmed || !mounted) return;

    final result = await detail.delete();
    if (!mounted) return;

    result.fold((_) {
      list.removeLocally(task.id);
      AppFeedback.success(context, 'Task deleted');
      if (router.canPop()) router.pop();
    }, (failure) => AppFeedback.error(context, failure));
  }

  Future<void> _postComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _postingComment = true);
    final result = await context.read<TaskDetailProvider>().addComment(body);
    if (!mounted) return;

    setState(() => _postingComment = false);
    result.fold((_) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }, (failure) => AppFeedback.error(context, failure));
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<TaskDetailProvider>();
    final task = detail.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          if (task != null)
            PopupMenuButton<String>(
              tooltip: 'Task actions',
              onSelected: (value) {
                if (value == 'edit') {
                  context.push(Routes.taskEditOf(task.id));
                } else {
                  _delete(task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit task')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete task',
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
            visible: detail.state.isRefreshing || detail.isMutating,
          ),
        ),
      ),
      body: task == null
          ? _buildPlaceholder(detail)
          : _buildTask(context, task),
    );
  }

  Widget _buildPlaceholder(TaskDetailProvider detail) {
    return switch (detail.state) {
      ErrorState(:final failure) => ErrorStateView(
        failure: failure,
        onRetry: detail.refresh,
      ),
      _ => const Padding(
        padding: EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 240, height: 22),
            SizedBox(height: Insets.lg),
            SkeletonCard(lines: 3),
            SizedBox(height: Insets.md),
            SkeletonCard(lines: 2),
          ],
        ),
      ),
    };
  }

  Widget _buildTask(BuildContext context, TaskItem task) {
    final theme = Theme.of(context);
    final detail = context.read<TaskDetailProvider>();
    final members = context.watch<MemberProvider>();
    final project = context.watch<ProjectListProvider>().byId(task.projectId);
    final assignee = members.userById(task.assigneeId);
    final due = task.dueDate;

    return RefreshIndicator(
      onRefresh: detail.refresh,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            if (project != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () =>
                    context.push(Routes.projectDetailOf(project.id)),
                icon: const Icon(Icons.folder_outlined, size: 16),
                label: Text(project.name),
              ),
            Text(task.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              children: [
                _TappableChip(
                  child: AccentChip.status(context, task.status),
                  onTap: () => showTaskStatusSheet(
                    context,
                    task: task,
                    onSelected: (status) async {
                      final result = await detail.changeStatus(status);
                      final updated = result.valueOrNull;
                      if (updated != null) _syncToList(updated);
                      return result;
                    },
                  ),
                ),
                _TappableChip(
                  child: AccentChip.priority(context, task.priority),
                  onTap: () => showTaskPrioritySheet(
                    context,
                    task: task,
                    onSelected: (priority) async {
                      final result = await detail.changePriority(priority);
                      final updated = result.valueOrNull;
                      if (updated != null) _syncToList(updated);
                      return result;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: UserAvatar(user: assignee),
                    title: Text(assignee?.name ?? 'Unassigned'),
                    subtitle: Text(
                      assignee == null
                          ? 'Nobody is working on this yet'
                          : members.memberById(task.assigneeId)?.role.label ??
                                '',
                    ),
                    trailing: TextButton(
                      onPressed: () => _changeAssignee(task),
                      child: Text(assignee == null ? 'Assign' : 'Change'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      due != null && task.isOverdue()
                          ? Icons.event_busy_rounded
                          : Icons.event_outlined,
                      color: due != null && task.isOverdue()
                          ? theme.colorScheme.error
                          : null,
                    ),
                    title: Text(
                      due == null ? 'No due date' : Dates.formatDue(due),
                    ),
                    subtitle: due == null ? null : Text(Dates.formatFull(due)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),

            if (task.description.trim().isNotEmpty) ...[
              const SectionHeader(title: 'Description'),
              Text(task.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: Insets.lg),
            ],

            SectionHeader(
              title: 'Activity',
              subtitle: 'Created ${Dates.relative(task.createdAt)}',
            ),
            _CommentSection(
              state: detail.comments,
              members: members,
              onRetry: detail.loadComments,
            ),
            const SizedBox(height: Insets.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment',
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                IconButton.filled(
                  onPressed: _postingComment ? null : _postComment,
                  icon: _postingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableChip extends StatelessWidget {
  const _TappableChip({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: child,
    );
  }
}

class _CommentSection extends StatelessWidget {
  const _CommentSection({
    required this.state,
    required this.members,
    required this.onRetry,
  });

  final ViewState<List<TaskComment>> state;
  final MemberProvider members;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (state) {
      InitialState() || LoadingState() => const Column(
        children: [
          SkeletonBox(width: double.infinity, height: 40),
          SizedBox(height: Insets.sm),
          SkeletonBox(width: double.infinity, height: 40),
        ],
      ),
      ErrorState(:final failure) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(failure.message, style: theme.textTheme.bodySmall),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      EmptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        child: Text(
          'No comments yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      SuccessState(:final data) => Column(
        children: [
          for (final comment in data)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    user: members.userById(comment.authorId),
                    size: 30,
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              members.userById(comment.authorId)?.name ??
                                  'Former member',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(width: Insets.sm),
                            Text(
                              Dates.relative(comment.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(comment.body, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    };
  }
}
