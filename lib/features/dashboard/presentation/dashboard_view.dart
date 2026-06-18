import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../core/providers/storage_providers.dart';
import '../../library/domain/models/document_record.dart';
import '../../pdf_editor/presentation/pdf_workspace_view.dart';
import '../../pdf_editor/controller/pdf_state_controller.dart';
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
                  Text(
                    "RECENT_SESSIONS //",
                    style: CyberpunkTheme.neonTextStyle(fontSize: 14, bold: true),
                  ).animate().shimmer(duration: 2.seconds),
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
                  (context, index) => _DocumentTile(doc: docs[index])
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.2, end: 0),
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
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          "CORE_WORKSPACE",
          style: CyberpunkTheme.neonTextStyle(fontSize: 24, bold: true),
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
          label: "AI Neural",
          color: CyberpunkTheme.neonPink,
          onTap: () {},
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.grid_view,
          label: "Sync Matrix",
          color: CyberpunkTheme.neonYellow,
          onTap: () {},
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
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
          decoration: CyberpunkTheme.glassDecoration(
            borderRadius: BorderRadius.circular(16),
            borderColor: color.withOpacity(0.5),
            showGlow: true,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: CyberpunkTheme.neonTextStyle(color: color, fontSize: 10, bold: true),
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
      decoration: CyberpunkTheme.glassDecoration(
        borderRadius: BorderRadius.circular(16),
        borderColor: Colors.white24,
      ),
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
              MaterialPageRoute(
                builder: (context) => PdfWorkspaceView(stateController: controller),
              ),
            );
          }
        },
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
