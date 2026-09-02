import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/project.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/async_list_view.dart';
import '../../widgets/project_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProjectListProvider>().loadIfNeeded(),
    );
  }

  Future<void> _confirmDelete(Project project) async {
    final provider = context.read<ProjectListProvider>();

    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Delete "${project.name}"?',
      message:
          'This removes the project and its ${project.taskCount} task(s). '
          'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final result = await provider.delete(project.id);
    if (!mounted) return;

    result.fold(
      (_) => AppFeedback.success(context, 'Project deleted'),
      (failure) => AppFeedback.error(context, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectListProvider>();
    final isAdmin = context.select<AuthProvider, bool>((auth) => auth.isAdmin);
    final orgName = context.select<AuthProvider, String?>(
      (auth) => auth.session?.user.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: RefreshingIndicator(visible: provider.state.isRefreshing),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab-new-project',
              onPressed: () => context.push(Routes.newProject),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
      body: AsyncListView<Project>(
        state: provider.state,
        onRefresh: provider.refresh,
        empty: EmptyStateView(
          icon: Icons.folder_open_rounded,
          title: 'No projects yet',
          message: isAdmin
              ? 'Create the first project for your organization and start adding work to it.'
              : 'Nothing has been shared with you yet. An admin can create the first project.',
          actionLabel: isAdmin ? 'Create a project' : null,
          onAction: isAdmin ? () => context.push(Routes.newProject) : null,
        ),
        builder: (context, projects) => AdaptiveList(
          itemCount: projects.length,
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.lg,
            Insets.lg,
            96,
          ),
          header: orgName == null
              ? null
              : SectionHeader(
                  title: projects.length == 1
                      ? '1 active project'
                      : '${projects.length} active projects',
                  subtitle: 'Pull down to refresh',
                ),
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              project: project,
              onTap: () => context.push(Routes.projectDetailOf(project.id)),
              onEdit: isAdmin
                  ? () => context.push(Routes.projectEditOf(project.id))
                  : null,
              onDelete: isAdmin ? () => _confirmDelete(project) : null,
            );
          },
        ),
      ),
    );
  }
}
