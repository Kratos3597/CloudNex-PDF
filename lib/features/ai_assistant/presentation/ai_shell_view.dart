import 'package:flutter/material.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import './ai_panel.dart';

class AiShellView extends StatelessWidget {
  const AiShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: CyberpunkTheme.glassDecoration(borderColor: CyberpunkTheme.neonCyan, showGlow: true),
          child: const ClipRRect(
            borderRadius: BorderRadius.zero,
            child: AiAssistantPanel(),
          ),
        ),
      ),
    );
  }
}
