import 'package:flutter/material.dart';
import '../../core/theme/pdf_pro_theme.dart';
import '../../engine/sync_engine.dart';
import '../widgets/status_capsule.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'analytics_screen.dart';
import 'signature_vault_screen.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    cloudSyncProvider.startAutoSync();
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const LibraryScreen(),
    const AnalyticsScreen(),
    const SignatureVaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // S25 Ultra Feature: Dynamic Status Capsule
          ListenableBuilder(
            listenable: cloudSyncProvider,
            builder: (context, _) {
              return Visibility(
                visible: cloudSyncProvider.isSyncing,
                child: const StatusCapsule(
                  status: "SYNCING_CLOUDNEX...",
                  icon: Icons.sync_rounded,
                  isLoading: true,
                ),
              );
            },
          ),
        ],
      ),
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
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: PdfProTheme.primaryBlue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
