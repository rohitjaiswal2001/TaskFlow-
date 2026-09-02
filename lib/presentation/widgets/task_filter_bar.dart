import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../providers/member_provider.dart';
import '../providers/task_list_provider.dart';
import 'task_filter_sheet.dart';

class TaskFilterBar extends StatefulWidget {
  const TaskFilterBar({super.key, this.showSearch = true});

  final bool showSearch;

  @override
  State<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends State<TaskFilterBar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<TaskListProvider>().filter.query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearchField(String query) {
    if (query == _searchController.text) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || query == _searchController.text) return;
      _searchController.text = query;
    });
  }

  Future<void> _openFilters() async {
    final provider = context.read<TaskListProvider>();
    final members = context.read<MemberProvider>();
    await members.loadIfNeeded();

    if (!mounted) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          TaskFilterSheet(initial: provider.filter, members: members.items),
    );

    if (result == null) return;
    provider.setFilter(result);
    _searchController.text = provider.filter.query;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskListProvider>();
    final activeCount = provider.filter.activeCount;

    _syncSearchField(provider.filter.query);

    final controls = [
      Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        child: IconButton.filledTonal(
          tooltip: 'Filters',
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
        ),
      ),
      _SortButton(provider: provider),
    ];

    if (!widget.showSearch) {
      return Row(mainAxisSize: MainAxisSize.min, children: controls);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            provider.setQuery('');
                          },
                        ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: provider.setQuery,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          ...controls,
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.provider});

  final TaskListProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<TaskSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.swap_vert_rounded),
      initialValue: provider.sort,
      onSelected: provider.setSort,
      itemBuilder: (context) => [
        for (final sort in TaskSort.values)
          PopupMenuItem(
            value: sort,
            child: Row(
              children: [
                Icon(
                  sort == provider.sort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Insets.md),
                Text('Sort by ${sort.label.toLowerCase()}'),
              ],
            ),
          ),
      ],
    );
  }
}
