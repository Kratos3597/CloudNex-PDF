import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'features/workspace/presentation/workspace_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge display for modern scaling
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent, // Modern transparent bar
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: CloudNexApp(),
    ),
  );
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNex PDF Editor',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.darkTheme,
      home: const WorkspaceShell(),
    );
  }
}
