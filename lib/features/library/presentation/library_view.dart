import 'package:cloudnex_pdf_reader/core/providers/pdf_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import '../../../core/providers/storage_providers.dart';
import '../../pdf_editor/presentation/pdf_workspace_view.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search your documents...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: PdfProTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: documentsAsync.when(
        data: (docs) {
          final filteredDocs = docs.where((d) => 
            d.fileName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? "Your library is empty" : "No results found",
                    style: const TextStyle(color: PdfProTheme.textLight),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () async {
                    final file = File(doc.filePath);
                    if (await file.exists()) {
                      final bytes = await file.readAsBytes();
                      pdfState.openDocument(
                        bytes, 
                        doc.fileName, 
                        filePath: doc.filePath,
                        initialPage: doc.lastOpenedPage,
                      );

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PdfWorkspaceView(stateController: pdfState)),
                      );
                    }
                  },
                  leading: const Icon(Icons.description_rounded, color: PdfProTheme.primaryBlue),
                  title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(doc.filePath, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
