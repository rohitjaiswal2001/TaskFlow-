import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setUpDependencies();

  runApp(const TaskFlowApp());
}
