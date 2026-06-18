import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/cyberpunk_theme.dart';
import '../../../../core/providers/storage_providers.dart';
import '../../pdf_editor/controller/pdf_state_controller.dart';
import '../../pdf_editor/presentation/pdf_workspace_view.dart';
import 'dart:io';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text("DATA_REPOSITORY //", style: CyberpunkTheme.neonTextStyle(fontSize: 24, bold: true)),
            const SizedBox(height: 8),
            Text("SECURE FILE BUFFER ENCLAVE", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonPink, fontSize: 11)),
            const SizedBox(height: 24),
            Expanded(
              child: documentsAsync.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Text("[!] NO FILES STORAGE INDEX FOUND", style: CyberpunkTheme.neonTextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: CyberpunkTheme.glassDecoration(borderColor: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                        child: ListTile(
                          onTap: () async {
                            final file = File(doc.filePath);
                            if (await file.exists()) {
                              final bytes = await file.readAsBytes();
                              final controller = PdfStateController();
                              controller.loadDocument(bytes);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PdfWorkspaceView(stateController: controller)),
                              );
                            }
                          },
                          leading: const Icon(Icons.code, color: CyberpunkTheme.neonCyan),
                          title: Text(doc.fileName.toUpperCase(), style: CyberpunkTheme.neonTextStyle(bold: true, fontSize: 13)),
                          subtitle: Text("PATH: ${doc.filePath}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                          trailing: const Icon(Icons.chevron_right, color: CyberpunkTheme.neonCyan),
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan)),
                error: (e, s) => Center(child: Text("BUFFER_ERR: $e", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonPink))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
