import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/repositories/project_repository.dart';
import '../../providers/project_detail_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../state/view_state.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/responsive.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.projectId});

  final String? projectId;

  bool get isEditing => projectId != null;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();

  ProjectStatus _status = ProjectStatus.active;
  bool _hydrated = false;
  bool _saving = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ProjectDetailProvider>().loadIfNeeded(),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(Project project) {
    if (_hydrated) return;
    _hydrated = true;
    _name.text = project.name;
    _description.text = project.description;
    _status = project.status;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    final projects = context.read<ProjectListProvider>();
    final draft = ProjectDraft(
      name: _name.text,
      description: _description.text,
      status: _status,
    );

    final result = widget.isEditing
        ? await projects.update(widget.projectId!, draft)
        : await projects.create(draft);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold((project) {
      if (widget.isEditing) {
        context.read<ProjectDetailProvider>().applyLocalUpdate(project);
      }
      AppFeedback.success(
        context,
        widget.isEditing ? 'Project updated' : 'Project created',
      );
      if (context.canPop()) context.pop();
    }, (failure) => setState(() => _failure = failure));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return _buildScaffold(context);

    final detail = context.watch<ProjectDetailProvider>();
    final project = detail.value;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit project')),
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

    _hydrate(project);
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final failure = _failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit project' : 'New project'),
      ),
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

                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: 'Project name',
                      errorText: fieldErrors['name'],
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: Validators.projectName,
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
                    validator: (value) =>
                        Validators.required(value, field: 'Description'),
                  ),
                  const SizedBox(height: Insets.lg),

                  Text('Status', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Insets.sm),
                  SegmentedButton<ProjectStatus>(
                    segments: [
                      for (final status in ProjectStatus.values)
                        ButtonSegment(value: status, label: Text(status.label)),
                    ],
                    selected: {_status},
                    onSelectionChanged: (selection) =>
                        setState(() => _status = selection.first),
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
                            widget.isEditing
                                ? 'Save changes'
                                : 'Create project',
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
