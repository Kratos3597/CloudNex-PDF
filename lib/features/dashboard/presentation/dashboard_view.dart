import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../pdf_editor/controller/pdf_state_controller.dart';
import '../../pdf_editor/presentation/pdf_workspace_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final PdfStateController _editorStateController = PdfStateController();

  Future<void> handleFileIngestion() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData:
          true, // Vital requirement to secure pure memory byte arrays across codespaces
    );

    if (result == null || result.files.single.bytes == null) return;

    final Uint8List rawBytes = result.files.single.bytes!;
    _editorStateController.loadDocument(rawBytes);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfWorkspaceView(stateController: _editorStateController),
      ),
    );
  }

  @override
  void dispose() {
    _editorStateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '// ACCESSING_WORKSPACE_CORE',
                style: TextStyle(
                  color: CyberpunkTheme.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'CLOUDNEX MATRIX',
                style: TextStyle(
                  color: CyberpunkTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),

              // Ingest Box
              GestureDetector(
                onTap: handleFileIngestion,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: CyberpunkTheme.glassDecoration(
                      borderColor: CyberpunkTheme.neonCyan.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_box_outlined,
                            color: CyberpunkTheme.neonCyan,
                            size: 32,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'INGEST NEW PDF ARRAY',
                            style: TextStyle(
                              color: CyberpunkTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}