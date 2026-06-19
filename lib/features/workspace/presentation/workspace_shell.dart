import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../dashboard/presentation/dashboard_view.dart';
import '../../library/presentation/library_view.dart';
import '../../analytics/presentation/analytics_view.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import 'package:cloudnex_pdf_reader/services/cloud_sync_service.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    cloudSyncProvider.startAutoSync();
  }

  final List<Widget> _pages = [
    const DashboardView(),
    const LibraryView(),
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex].animate(key: ValueKey(_selectedIndex)).fadeIn(duration: 400.ms).slideY(begin: 0.02, end: 0),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 10,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: PdfProTheme.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: PdfProTheme.primaryBlue),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: PdfProTheme.primaryBlue),
            label: 'Activity',
          ),
        ],
      ),
    );
  }
}
