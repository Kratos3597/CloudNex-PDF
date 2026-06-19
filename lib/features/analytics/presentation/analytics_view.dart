import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../services/analytics_service.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text("SYSTEM_METRICS //", style: CyberpunkTheme.neonTextStyle(fontSize: 24, bold: true)),
            const SizedBox(height: 8),
            Text("OPERATIONAL AUDIT TRAIL & USAGE ANALYTICS", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonPink, fontSize: 11)),
            const SizedBox(height: 32),
            
            _buildStatGrid(),
            const SizedBox(height: 32),
            
            Text("AUDIT_LOG //", style: CyberpunkTheme.neonTextStyle(fontSize: 14, bold: true)),
            const SizedBox(height: 16),
            Expanded(child: _buildAuditTrail()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = analyticsService.getActionStats();
    return Row(
      children: [
        _buildStatCard("OPENED", stats["OPEN_DOCUMENT"]?.toString() ?? "0", CyberpunkTheme.neonCyan),
        const SizedBox(width: 16),
        _buildStatCard("MODIFIED", stats["MODIFY_DOCUMENT"]?.toString() ?? "0", CyberpunkTheme.neonPink),
        const SizedBox(width: 16),
        _buildStatCard("EXPORTED", stats["EXPORT_DOCUMENT"]?.toString() ?? "0", CyberpunkTheme.neonGreen),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: CyberpunkTheme.glassDecoration(borderColor: color.withValues(alpha: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CyberpunkTheme.neonTextStyle(color: color, fontSize: 10, bold: true)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrail() {
    return ListenableBuilder(
      listenable: analyticsService,
      builder: (context, _) {
        final logs = analyticsService.auditTrail;
        if (logs.isEmpty) {
          return Center(child: Text("[!] NO LOG DATA FOUND", style: CyberpunkTheme.neonTextStyle(color: Colors.white24)));
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: CyberpunkTheme.glassDecoration(
                borderColor: Colors.white12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActionColor(log.action).withValues(alpha: 0.1),
                      border: Border.all(color: _getActionColor(log.action)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(log.action, style: TextStyle(color: _getActionColor(log.action), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.documentName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text("BY: ${log.user} // ${DateFormat('HH:mm:ss').format(log.timestamp)}", 
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case "OPEN_DOCUMENT": return CyberpunkTheme.neonCyan;
      case "MODIFY_DOCUMENT": return CyberpunkTheme.neonPink;
      case "EXPORT_DOCUMENT": return CyberpunkTheme.neonGreen;
      default: return Colors.white;
    }
  }
}
