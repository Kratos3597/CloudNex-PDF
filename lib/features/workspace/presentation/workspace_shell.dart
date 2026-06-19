import 'package:cloudnex_pdf_reader/services/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../dashboard/presentation/dashboard_view.dart';
import '../../library/presentation/library_view.dart';
import '../../ai_assistant/presentation/ai_shell_view.dart';
import '../../analytics/presentation/analytics_view.dart';
import '../../../core/theme/cyberpunk_theme.dart';

class WorkspaceShell extends ConsumerStatefulWidget {
  const WorkspaceShell({super.key});

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    cloudSyncProvider.startAutoSync();
  }

  final List<Widget> _pages = [
    const DashboardView(),
    const LibraryView(),
    const AiShellView(),
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1100;
    final isTablet = size.width > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Use persistent sidebar for tablets in landscape or any screen > 1100px
    final showSidebar = isDesktop || (isTablet && isLandscape);

    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      extendBody: true, // Allows glass effect to flow behind bottom nav
      body: Row(
        children: [
          if (showSidebar)
            _buildSidebar(isDesktop || isTablet).animate().slideX(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOut),
          Expanded(
            child: _pages[_selectedIndex].animate(key: ValueKey(_selectedIndex)).fadeIn(duration: 400.ms).slideY(begin: 0.02, end: 0),
          ),
        ],
      ),
      bottomNavigationBar: !showSidebar
          ? Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 30), // Floating Apple-style
              height: 64,
              decoration: CyberpunkTheme.glassDecoration(
                borderRadius: BorderRadius.circular(32),
                borderColor: Colors.white10,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: CyberpunkTheme.glassBlurFilter,
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    selectedItemColor: CyberpunkTheme.neonCyan,
                    unselectedItemColor: Colors.white24,
                    backgroundColor: Colors.transparent, // Important for glass
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'HOME'),
                      BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'FILES'),
                      BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_rounded), label: 'NEURAL'),
                      BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'DATA'),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSidebar(bool isDesktop) {
    final width = _isSidebarExpanded ? 240.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: CyberpunkTheme.backgroundDark,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildSidebarLogo(),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: "Dashboard",
                  isSelected: _selectedIndex == 0,
                  isExpanded: _isSidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  label: "PDF Library",
                  isSelected: _selectedIndex == 1,
                  isExpanded: _isSidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _SidebarItem(
                  icon: Icons.auto_awesome_outlined,
                  label: "AI Assistant",
                  isSelected: _selectedIndex == 2,
                  isExpanded: _isSidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _SidebarItem(
                  icon: Icons.analytics_outlined,
                  label: "Analytics",
                  isSelected: _selectedIndex == 3,
                  isExpanded: _isSidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
          _buildCollapseButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarLogo() {
    return _isSidebarExpanded
        ? Text(
            "CLOUDNEX_OS",
            style: CyberpunkTheme.neonTextStyle(
              fontSize: 18,
              bold: true,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: CyberpunkTheme.neonCyan.withValues(alpha: 0.3))
        : const Icon(Icons.cloud, color: CyberpunkTheme.neonCyan, size: 32);
  }

  Widget _buildCollapseButton() {
    return Column(
      children: [
        ListenableBuilder(
          listenable: cloudSyncProvider,
          builder: (context, _) {
            if (!cloudSyncProvider.isSyncing) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1, color: CyberpunkTheme.neonCyan),
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 8),
                    Text("SYNCING...", style: CyberpunkTheme.neonTextStyle(fontSize: 8)),
                  ]
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? CyberpunkTheme.neonCyan.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: isSelected ? CyberpunkTheme.neonCyan : Colors.white70),
              if (isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? CyberpunkTheme.neonCyan : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
