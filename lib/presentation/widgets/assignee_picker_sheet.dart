import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/org_member.dart';
import '../state/view_state.dart';
import 'skeleton.dart';
import 'state_views.dart';
import 'user_avatar.dart';

class AssigneeChoice {
  const AssigneeChoice(this.userId);

  const AssigneeChoice.unassign() : userId = null;

  final String? userId;

  bool get isUnassign => userId == null;
}

class AssigneePickerSheet extends StatelessWidget {
  const AssigneePickerSheet({
    super.key,
    required this.state,
    required this.currentAssigneeId,
    required this.onRetry,
  });

  final ViewState<List<OrgMember>> state;
  final String? currentAssigneeId;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign to', style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.xs),
            Text(
              'Only people in your organization can be assigned.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.md),
            Flexible(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final members = state.dataOrNull;

    if (members == null) {
      return switch (state) {
        ErrorState(:final failure) => ErrorStateView(
          failure: failure,
          onRetry: onRetry,
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: Insets.lg),
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 44),
              SizedBox(height: Insets.sm),
              SkeletonBox(width: double.infinity, height: 44),
              SizedBox(height: Insets.sm),
              SkeletonBox(width: double.infinity, height: 44),
            ],
          ),
        ),
      };
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (currentAssigneeId != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const UserAvatar.unassigned(),
            title: const Text('Unassign'),
            subtitle: const Text('Leave this task without an owner'),
            onTap: () =>
                Navigator.of(context).pop(const AssigneeChoice.unassign()),
          ),
        for (final member in members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(user: member.user),
            title: Text(member.user.name),
            subtitle: Text('${member.role.label} · ${member.user.email}'),
            trailing: member.userId == currentAssigneeId
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () =>
                Navigator.of(context).pop(AssigneeChoice(member.userId)),
          ),
      ],
    );
  }
}
