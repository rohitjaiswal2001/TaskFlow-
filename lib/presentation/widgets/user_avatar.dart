import 'package:flutter/material.dart';

import '../../core/utils/string_extensions.dart';
import '../../domain/entities/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 36});

  const UserAvatar.unassigned({super.key, this.size = 36}) : user = null;

  final AppUser? user;
  final double size;

  static const _palette = [
    Color(0xFF5B5BD6),
    Color(0xFF0E7C86),
    Color(0xFFB5462B),
    Color(0xFF7A3EA1),
    Color(0xFF1F6B3A),
    Color(0xFFA8437C),
  ];

  @override
  Widget build(BuildContext context) {
    final person = user;
    final theme = Theme.of(context);

    if (person == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.55,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final color = _palette[person.id.hashCode.abs() % _palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        person.name.initials,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
