import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = Radii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.55 + 0.45 * (0.5 - (_controller.value - 0.5).abs()) * 2,
        child: child,
      ),
      child: widget.child,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 160, height: 16),
            const SizedBox(height: Insets.md),
            for (var i = 0; i < lines; i++) ...[
              SkeletonBox(width: i.isEven ? double.infinity : 220, height: 11),
              const SizedBox(height: Insets.sm),
            ],
            const SizedBox(height: Insets.xs),
            Row(
              children: const [
                SkeletonBox(width: 72, height: 22, radius: Radii.pill),
                SizedBox(width: Insets.sm),
                SkeletonBox(width: 56, height: 22, radius: Radii.pill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.lines = 2});

  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Insets.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: Insets.md),
      itemBuilder: (_, _) => SkeletonCard(lines: lines),
    );
  }
}
