import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import '../services/analytics_service.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Insights'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatSummary(),
            const SizedBox(height: 32),
            Text(
              "Recent Activity",
              style: PdfProTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildLogList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummary() {
    final stats = analyticsService.getActionStats();
    return Row(
      children: [
        _buildSummaryCard("Viewed", stats["OPEN_DOCUMENT"]?.toString() ?? "0", PdfProTheme.primaryBlue),
        const SizedBox(width: 12),
        _buildSummaryCard("Edited", stats["MODIFY_DOCUMENT"]?.toString() ?? "0", PdfProTheme.accentIndigo),
        const SizedBox(width: 12),
        _buildSummaryCard("Exported", stats["EXPORT_DOCUMENT"]?.toString() ?? "0", PdfProTheme.successGreen),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: PdfProTheme.textDark, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return ListenableBuilder(
      listenable: analyticsService,
      builder: (context, _) {
        final logs = analyticsService.auditTrail;
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text("No activity recorded yet", style: TextStyle(color: PdfProTheme.textLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getActionColor(log.action).withValues(alpha: 0.1),
                  child: Icon(_getActionIcon(log.action), color: _getActionColor(log.action), size: 18),
                ),
                title: Text(log.documentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(DateFormat('MMM d, HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 11)),
                trailing: Text(log.action.replaceAll('_', ' '), style: TextStyle(fontSize: 10, color: _getActionColor(log.action), fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('OPEN')) return Icons.visibility_rounded;
    if (action.contains('MODIFY')) return Icons.edit_rounded;
    return Icons.ios_share_rounded;
  }

  Color _getActionColor(String action) {
    if (action.contains('OPEN')) return PdfProTheme.primaryBlue;
    if (action.contains('MODIFY')) return PdfProTheme.accentIndigo;
    return PdfProTheme.successGreen;
  }
}
