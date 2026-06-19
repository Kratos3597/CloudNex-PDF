import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/pdf_pro_theme.dart';
import 'features/workspace/presentation/workspace_shell.dart';
import 'core/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    const ProviderScope(
      child: PdfProApp(),
    ),
  );
}

class PdfProApp extends ConsumerWidget {
  const PdfProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'CloudNex PDF Pro',
      debugShowCheckedModeBanner: false,
      theme: PdfProTheme.lightTheme,
      darkTheme: PdfProTheme.darkTheme,
      themeMode: themeMode,
      home: const WorkspaceShell(),
    );
  }
}
