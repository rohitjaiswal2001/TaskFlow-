import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ActivityDetector extends StatelessWidget {
  const ActivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => context.read<AuthProvider>().registerActivity(),
      child: child,
    );
  }
}
