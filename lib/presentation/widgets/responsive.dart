import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AdaptiveList extends StatelessWidget {
  const AdaptiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(Insets.lg),
    this.controller,
    this.header,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;
  final ScrollController? controller;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final columns = isWideLayout(context) ? 2 : 1;

    if (columns == 1) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        itemCount: itemCount + (header != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: Insets.md),
        itemBuilder: (context, index) {
          if (header != null) {
            if (index == 0) return header!;
            return itemBuilder(context, index - 1);
          }
          return itemBuilder(context, index);
        },
      );
    }

    return CustomScrollView(
      controller: controller,
      slivers: [
        if (header != null)
          SliverPadding(
            padding: padding.copyWith(bottom: 0),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisSpacing: Insets.md,
              crossAxisSpacing: Insets.md,
              mainAxisExtent: 148,
            ),
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
