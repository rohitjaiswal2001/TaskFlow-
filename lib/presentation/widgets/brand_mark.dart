import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 44,
    this.alignment = Alignment.centerLeft,
  });

  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.tertiary, 0.6)!,
            ],
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}

class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Insets.lg),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
