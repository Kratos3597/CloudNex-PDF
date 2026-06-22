import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/pdf_pro_theme.dart';
import '../../core/providers/storage_providers.dart';
import '../../storage/models/document_model.dart';
import 'editor_screen.dart';
import '../../core/providers/pdf_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../engine/render/render_engine.dart';
import 'dart:io';
import 'dart:typed_data';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);
    final pdfState = ref.watch(pdfStateProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CloudNex PDF Pro'),
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: PdfProTheme.textLight),
            onPressed: () {
              ref.read(themeProvider.notifier).state = 
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeMode == ThemeMode.dark ? Colors.white : PdfProTheme.textDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "What would you like to do today?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildActionGrid(context, ref),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Documents",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          documentsAsync.when(
            data: (docs) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DocumentCard(doc: docs[index], pdfState: pdfState),
                  childCount: docs.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverToBoxAdapter(child: Text("Error loading documents: $e")),
          ),
          if (documentsAsync.value?.isEmpty ?? true)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text("No documents in your library", style: TextStyle(color: PdfProTheme.textLight)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleImport(ref),
        label: const Text("Open PDF"),
        icon: const Icon(Icons.add),
        backgroundColor: PdfProTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.upload_file_rounded,
          label: "Upload",
          color: PdfProTheme.primaryBlue,
          onTap: () => _handleImport(ref),
        ),
        const SizedBox(width: 16),
        _QuickAction(
          icon: Icons.merge_type_rounded,
          label: "Merge",
          color: PdfProTheme.accentIndigo,
          onTap: () => _handleMerge(context, ref),
        ),
        const SizedBox(width: 16),
        _QuickAction(
          icon: Icons.auto_graph_rounded,
          label: "Activity",
          color: PdfProTheme.successGreen,
          onTap: () {},
        ),
      ],
    );
  }

  Future<void> _handleMerge(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.length >= 2) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final List<Uint8List> docs = [];
      for (var file in result.files) {
        if (file.path != null) {
          docs.add(await File(file.path!).readAsBytes());
        }
      }

      final mergedBytes = await RenderEngine.mergeDocuments(docs);
      
      if (!context.mounted) return;
      Navigator.pop(context);

      final record = DocumentRecord()
        ..filePath = "MERGED_${DateTime.now().millisecondsSinceEpoch}.pdf"
        ..fileName = "Merged Document.pdf"
        ..lastOpenedDate = DateTime.now();
      
      final savePath = await RenderEngine.saveDocument(mergedBytes, record.fileName);
      record.filePath = savePath;

      await ref.read(databaseProvider).saveDocument(record);
      ref.invalidate(documentListProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documents merged successfully")));
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least 2 documents to merge")));
    }
  }

  Future<void> _handleImport(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final record = DocumentRecord()
        ..filePath = file.path
        ..fileName = result.files.single.name
        ..lastOpenedDate = DateTime.now();

      await ref.read(databaseProvider).saveDocument(record);
      ref.invalidate(documentListProvider);
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final DocumentRecord doc;
  final dynamic pdfState;

  const _DocumentCard({required this.doc, required this.pdfState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              MaterialPageRoute(
                builder: (context) => EditorScreen(stateController: pdfState),
              ),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File no longer exists")));
          }
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PdfProTheme.primaryBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded, color: PdfProTheme.primaryBlue),
        ),
        title: Text(
          doc.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "Edited ${doc.lastOpenedDate.day}/${doc.lastOpenedDate.month}",
          style: const TextStyle(color: PdfProTheme.textLight, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: PdfProTheme.textLight),
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Remove from Recent?"),
                  content: const Text("This will remove the record from your history. The file will remain on your device."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: PdfProTheme.errorRed))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(databaseProvider).deleteDocument(doc.id);
                ref.invalidate(documentListProvider);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: PdfProTheme.errorRed),
                  SizedBox(width: 8),
                  Text("Remove", style: TextStyle(color: PdfProTheme.errorRed)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
