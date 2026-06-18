import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/cyberpunk_theme.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text("SYS_ANALYTICS //", style: CyberpunkTheme.neonTextStyle(fontSize: 24, bold: true)),
            const SizedBox(height: 8),
            Text("DATA TELEMETRY CORE MATRIX", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonYellow, fontSize: 11)),
            const SizedBox(height: 32),
            _buildStatCard("NETWORK NODE STATE", "OPERATIONAL / SECURE", CyberpunkTheme.neonGreen),
            const SizedBox(height: 16),
            _buildStatCard("AI AGENT CORE LOAD", "78.4% CAPACITANCE", CyberpunkTheme.neonCyan),
            const SizedBox(height: 16),
            _buildStatCard("MEMETIC CACHE SECTORS", "ALPHA-0 / OMEGA-9", CyberpunkTheme.neonPink),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String data, Color neonColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: CyberpunkTheme.glassDecoration(borderColor: neonColor.withOpacity(0.4), showGlow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CyberpunkTheme.neonTextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 8),
          Text(data, style: CyberpunkTheme.neonTextStyle(color: neonColor, fontSize: 16, bold: true)),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
