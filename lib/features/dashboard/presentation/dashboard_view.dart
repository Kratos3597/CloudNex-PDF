import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../core/providers/storage_providers.dart';
import '../../library/domain/models/document_record.dart';
import 'dart:io';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(context, ref),
                  const SizedBox(height: 32),
                  const Text(
                    "RECENT DOCUMENTS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          documentsAsync.when(
            data: (docs) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DocumentTile(doc: docs[index]),
                  childCount: docs.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Text("Error: $e")),
          ),
          if (documentsAsync.value?.isEmpty ?? true)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text("No documents found.", style: TextStyle(color: Colors.white24)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          "WORKSPACE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.add,
          label: "New PDF",
          color: CyberpunkTheme.neonCyan,
          onTap: () => _handleImport(ref),
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.auto_awesome,
          label: "AI Chat",
          color: CyberpunkTheme.neonPink,
          onTap: () {},
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.grid_view,
          label: "Merge",
          color: Colors.amber,
          onTap: () {},
        ),
      ],
    );
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

      await ref.read(isarServiceProvider).saveDocument(record);
      ref.invalidate(documentListProvider);
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentRecord doc;

  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CyberpunkTheme.neonCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: CyberpunkTheme.neonCyan, size: 20),
        ),
        title: Text(
          doc.fileName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Last opened: ${doc.lastOpenedDate.day}/${doc.lastOpenedDate.month}",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            doc.isFavorite ? Icons.star : Icons.star_border,
            color: doc.isFavorite ? Colors.amber : Colors.white24,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
