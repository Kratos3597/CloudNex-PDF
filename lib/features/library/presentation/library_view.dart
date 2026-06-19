import 'package:cloudnex_pdf_reader/features/ai_assistant/services/ai_service.dart';
import 'package:cloudnex_pdf_reader/core/providers/pdf_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/cyberpunk_theme.dart';
import '../../../../core/providers/storage_providers.dart';
import '../presentation/../../pdf_editor/presentation/pdf_workspace_view.dart';
import 'dart:io';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentListProvider);
    final pdfState = ref.watch(pdfStateProvider);
    final aiService = ref.watch(aiServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DATA_REPOSITORY //", style: CyberpunkTheme.neonTextStyle(fontSize: 24, bold: true)),
                    const SizedBox(height: 8),
                    Text("SECURE FILE BUFFER ENCLAVE", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonPink, fontSize: 11)),
                  ],
                ),
                _buildSearchBar(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: documentsAsync.when(
                data: (docs) {
                  var filteredDocs = docs;
                  if (_searchQuery.isNotEmpty) {
                    final titles = docs.map((d) => d.fileName).toList();
                    final semanticResults = aiService.semanticFilter(titles, _searchQuery);
                    filteredDocs = docs.where((d) => semanticResults.contains(d.fileName)).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(_searchQuery.isEmpty ? "[!] NO FILES STORAGE INDEX FOUND" : "[!] NO SEMANTIC MATCHES FOUND", 
                          style: CyberpunkTheme.neonTextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: CyberpunkTheme.glassDecoration(borderColor: CyberpunkTheme.neonCyan.withValues(alpha: 0.3)),
                        child: ListTile(
                          onTap: () async {
                            final file = File(doc.filePath);
                            if (await file.exists()) {
                              final bytes = await file.readAsBytes();
                              pdfState.openDocument(bytes, doc.fileName);
                              
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PdfWorkspaceView(stateController: pdfState)),
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

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      height: 40,
      decoration: CyberpunkTheme.glassDecoration(
        borderColor: CyberpunkTheme.neonCyan.withValues(alpha: 0.2),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: "SEMANTIC_SEARCH...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          prefixIcon: const Icon(Icons.search, color: CyberpunkTheme.neonCyan, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(
            icon: const Icon(Icons.close, color: CyberpunkTheme.neonPink, size: 14),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          ) : null,
        ),
      ),
    );
  }
}
