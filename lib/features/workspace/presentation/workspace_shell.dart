import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_view.dart';
import '../../library/presentation/library_view.dart';
import '../../analytics/presentation/analytics_view.dart';
import '../../../core/theme/pdf_pro_theme.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const LibraryView(),
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
