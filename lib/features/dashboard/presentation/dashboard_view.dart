import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../pdf_editor/controller/pdf_state_controller.dart';
import '../../pdf_editor/presentation/pdf_workspace_view.dart';
import '../../pdf_editor/services/pdf_modifier_service.dart';

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
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final Uint8List rawBytes = result.files.single.bytes!;

    if (PdfModifierService.isDocumentEncrypted(rawBytes)) {
      if (!mounted) return;
      _launchSecurityDecryptionModal(rawBytes);
    } else {
      _bootWorkspace(rawBytes, null);
    }
  }

  void _launchSecurityDecryptionModal(Uint8List rawBytes) {
    final TextEditingController passwordController = TextEditingController();
    String? errorTerminalFeedback;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: CyberpunkTheme.glassBlurFilter,
              child: Container(
                decoration: CyberpunkTheme.glassDecoration(
                  borderColor: CyberpunkTheme.neonPink.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock,
                            color: CyberpunkTheme.neonPink, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CRYPTOGRAPHIC VAULT DETECTED',
                          style: TextStyle(
                              color: CyberpunkTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.25),
                        hintText: 'ENTER DECRYPTION KEY...',
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 12),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: CyberpunkTheme.neonPink
                                    .withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: CyberpunkTheme.neonPink)),
                      ),
                    ),
                    if (errorTerminalFeedback != null) ...[
                      const SizedBox(height: 12),
                      Text(errorTerminalFeedback!,
                          style: const TextStyle(
                              color: CyberpunkTheme.neonPink,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ABORT',
                              style: TextStyle(
                                  color: CyberpunkTheme.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CyberpunkTheme.neonPink.withValues(alpha: 0.2),
                            side: const BorderSide(
                                color: CyberpunkTheme.neonPink),
                          ),
                          onPressed: () {
                            final inputKey = passwordController.text;
                            final bool isValid =
                                PdfModifierService.validatePassword(
                                    rawBytes, inputKey);

                            if (isValid) {
                              Navigator.pop(context);
                              _bootWorkspace(rawBytes, inputKey);
                            } else {
                              setModalState(() {
                                errorTerminalFeedback =
                                    '// ERROR: INVALID CRYPTO SECURITY PHRASE';
                              });
                            }
                          },
                          child: const Text('DECRYPT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _bootWorkspace(Uint8List bytes, String? password) {
    _editorStateController.loadDocument(bytes, password: password);
    Navigator.of(context).push(
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
