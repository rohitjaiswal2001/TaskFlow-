import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/task_item.dart';
import '../../../domain/entities/task_status.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../providers/member_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_detail_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../state/view_state.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/assignee_picker_sheet.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/responsive.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/user_avatar.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId, this.initialProjectId});

  final String? taskId;
  final String? initialProjectId;

  bool get isEditing => taskId != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  String? _projectId;
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  DateTime? _dueDate;

  bool _hydrated = false;
  bool _saving = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectListProvider>().loadIfNeeded();
      context.read<MemberProvider>().loadIfNeeded();
      if (widget.isEditing) context.read<TaskDetailProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(TaskItem task) {
    if (_hydrated) return;
    _hydrated = true;
    _title.text = task.title;
    _description.text = task.description;
    _projectId = task.projectId;
    _status = task.status;
    _priority = task.priority;
    _assigneeId = task.assigneeId;
    _dueDate = task.dueDate;
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select a due date',
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _pickAssignee() async {
    final members = context.read<MemberProvider>();
    await members.loadIfNeeded();
    if (!mounted) return;

    final choice = await showModalBottomSheet<AssigneeChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssigneePickerSheet(
        state: members.state,
        currentAssigneeId: _assigneeId,
        onRetry: members.refresh,
      ),
    );

    if (choice == null) return;
    setState(() => _assigneeId = choice.userId);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final projectId = _projectId;
    if (projectId == null) {
      setState(
        () => _failure = const ValidationFailure(
          'Choose a project for this task.',
          fieldErrors: {'project_id': 'Choose a project'},
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _failure = null;
    });

    final tasks = context.read<TaskListProvider>();
    final draft = TaskDraft(
      projectId: projectId,
      title: _title.text,
      description: _description.text,
      status: _status,
      priority: _priority,
      assigneeId: _assigneeId,
      dueDate: _dueDate,
    );

    final result = widget.isEditing
        ? await tasks.update(widget.taskId!, draft)
        : await tasks.create(draft);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold((task) {
      if (widget.isEditing) {
        context.read<TaskDetailProvider>().load(silent: true);
      }
      AppFeedback.success(
        context,
        widget.isEditing ? 'Task updated' : 'Task created',
      );
      if (context.canPop()) context.pop();
    }, (failure) => setState(() => _failure = failure));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return _buildScaffold(context);

    final detail = context.watch<TaskDetailProvider>();
    final task = detail.value;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit task')),
        body: switch (detail.state) {
          ErrorState(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: detail.refresh,
          ),
          _ => const Padding(
            padding: EdgeInsets.all(Insets.lg),
            child: Column(
              children: [
                SkeletonBox(width: double.infinity, height: 56),
                SizedBox(height: Insets.lg),
                SkeletonBox(width: double.infinity, height: 120),
              ],
            ),
          ),
        },
      );
    }

    _hydrate(task);
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final projects = context.watch<ProjectListProvider>().items;
    final members = context.watch<MemberProvider>();
    final assignee = members.userById(_assigneeId);
    final failure = _failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task')),
      body: SafeArea(
        child: ContentWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (failure != null && failure is! ValidationFailure)
                    FormErrorBanner(message: failure.message),

                  DropdownButtonFormField<String>(
                    initialValue: _projectId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Project',
                      errorText: fieldErrors['project_id'],
                    ),
                    items: [
                      for (final project in projects)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],

                    onChanged: widget.isEditing
                        ? null
                        : (value) => setState(() => _projectId = value),
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      errorText: fieldErrors['title'],
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: Validators.taskTitle,
                    autofocus: !widget.isEditing,
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                  ),
                  const SizedBox(height: Insets.lg),

                  Text('Status', style: theme.textTheme.labelLarge),
                  const SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: Insets.sm,
                    children: [
                      for (final status in TaskStatus.values)
                        ChoiceChip(
                          label: Text(status.label),
                          selected: _status == status,
                          showCheckmark: false,
                          avatar: CircleAvatar(
                            radius: 5,
                            backgroundColor: statusColor(context, status),
                          ),
                          onSelected: (_) => setState(() => _status = status),
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  Text('Priority', style: theme.textTheme.labelLarge),
                  const SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: Insets.sm,
                    children: [
                      for (final priority in TaskPriority.values)
                        ChoiceChip(
                          label: Text(priority.label),
                          selected: _priority == priority,
                          showCheckmark: false,
                          avatar: CircleAvatar(
                            radius: 5,
                            backgroundColor: priorityColor(context, priority),
                          ),
                          onSelected: (_) =>
                              setState(() => _priority = priority),
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: UserAvatar(user: assignee, size: 32),
                          title: Text(assignee?.name ?? 'Unassigned'),
                          subtitle: Text(
                            fieldErrors['assignee_id'] ?? 'Tap to change',
                            style: fieldErrors.containsKey('assignee_id')
                                ? TextStyle(color: theme.colorScheme.error)
                                : null,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _pickAssignee,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(
                            _dueDate == null
                                ? 'No due date'
                                : Dates.formatDue(_dueDate!),
                          ),
                          subtitle: Text(
                            _dueDate == null
                                ? 'Tap to set one'
                                : Dates.formatFull(_dueDate!),
                          ),
                          trailing: _dueDate == null
                              ? const Icon(Icons.chevron_right_rounded)
                              : IconButton(
                                  tooltip: 'Clear due date',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () =>
                                      setState(() => _dueDate = null),
                                ),
                          onTap: _pickDueDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.xl),

                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(
                            widget.isEditing ? 'Save changes' : 'Create task',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
