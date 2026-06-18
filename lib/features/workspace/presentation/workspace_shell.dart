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

  final List<Widget> _pages = [
    const DashboardView(),
    const LibraryView(),
    const AiShellView(),
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final isTablet = MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width <= 1100;

    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: Row(
        children: [
          if (isDesktop || isTablet)
            _buildSidebar(isDesktop).animate().slideX(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOut),
          Expanded(
            child: _pages[_selectedIndex].animate(key: ValueKey(_selectedIndex)).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          ),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.2), width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedItemColor: CyberpunkTheme.neonCyan,
                unselectedItemColor: Colors.white24,
                backgroundColor: CyberpunkTheme.backgroundDark,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: CyberpunkTheme.neonTextStyle(fontSize: 10, bold: true),
                unselectedLabelStyle: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'HOME'),
                  BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'FILES'),
                  BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'NEURAL'),
                  BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'DATA'),
                ],
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
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
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
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: CyberpunkTheme.neonCyan.withOpacity(0.3))
        : const Icon(Icons.cloud, color: CyberpunkTheme.neonCyan, size: 32);
  }

  Widget _buildCollapseButton() {
    return IconButton(
      icon: Icon(
        _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
        color: Colors.white54,
      ),
      onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
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
            color: isSelected ? CyberpunkTheme.neonCyan.withOpacity(0.1) : Colors.transparent,
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
