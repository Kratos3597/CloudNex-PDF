import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'features/dashboard/presentation/dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CyberpunkTheme.backgroundDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CloudNexApp());
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNex PDF Editor',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.darkTheme,
      home: const DashboardView(),
    );
  }
}