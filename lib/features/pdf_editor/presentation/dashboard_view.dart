import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../controller/pdf_state_controller.dart';
import '../services/pdf_modifier_service.dart';
import 'pdf_workspace_view.dart';

class DashboardView extends StatefulWidget {
  final PdfStateController stateController;

  const DashboardView({super.key, required this.stateController});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  /// Ingests files securely and routes encrypted streams to validation gates
  Future<void> _handleFileIngestion() async {
    final FilePickerResult? targetFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Memory lifecycle optimization (Point 2)
    );

    if (targetFile == null || targetFile.files.single.bytes == null) return;

    final rawFileBytes = targetFile.files.single.bytes!;

    // POINT 9: Intercept if cryptographic security locks are present
    if (PdfModifierService.isDocumentEncrypted(rawFileBytes)) {
      if (!mounted) return;
      _launchSecurityDecryptionModal(rawFileBytes);
    } else {
      _bootWorkspace(rawFileBytes, null);
    }
  }

  /// Displays the glassmorphic password input portal
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
                        fillColor: Colors.black25,
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
                              Navigator.pop(
                                  context); // Close the entry gate modal
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
    widget.stateController.loadDocument(bytes, password: password);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PdfWorkspaceView(stateController: widget.stateController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '⚡ CLOUDNEX // MATRIX ⚡',
              style: TextStyle(
                  color: CyberpunkTheme.neonCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0),
            ),
            const SizedBox(height: 8),
            const Text(
              'ENGINEERING UTILITY SUBSYSTEM',
              style: TextStyle(
                  color: CyberpunkTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2.0),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _handleFileIngestion,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: BackdropFilter(
                  filter: CyberpunkTheme.glassBlurFilter,
                  child: Container(
                    width: 260,
                    height: 120,
                    decoration: CyberpunkTheme.glassDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_open,
                            size: 36, color: CyberpunkTheme.neonCyan),
                        SizedBox(height: 12),
                        Text(
                          'INGEST SOURCE MATRIX',
                          style: TextStyle(
                              color: CyberpunkTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5),
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
    );
  }
}