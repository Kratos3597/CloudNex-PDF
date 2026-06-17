import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../controller/pdf_state_controller.dart';
import '../services/pdf_modifier_service.dart';
import 'signature_pad_view.dart';

class PdfWorkspaceView extends StatefulWidget {
  final PdfStateController stateController;
  const PdfWorkspaceView({super.key, required this.stateController});

  @override
  State<PdfWorkspaceView> createState() => _PdfWorkspaceViewState();
}

class _PdfWorkspaceViewState extends State<PdfWorkspaceView> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  final List<List<Offset>> _activeDrawingPaths = [];
  List<Offset> _currentStrokePoints = [];
  bool _showToolMenu = false;
  bool _showSecurityPanel = false;

  // --- ACTIONS ---

  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;
    final bool success = await PdfModifierService.saveDocumentViaSystemPicker(
      bytes: currentBytes,
      suggestedName: 'cloudnex_sanitized_export.pdf',
    );
    if (!mounted) return;
    if (success) widget.stateController.clearActiveSessionCache();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: CyberpunkTheme.backgroundDark,
      content: Text(success ? '// EXPORT COMPLETED' : '// EXPORT ABORTED',
          style: TextStyle(color: success ? CyberpunkTheme.neonGreen : CyberpunkTheme.neonPink)),
    ));
  }

  Future<void> _executeSystemShare() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;
    await PdfModifierService.shareDocumentViaSystemSheet(bytes: currentBytes, fileName: 'cloudnex_shared.pdf');
  }

  Future<void> _applyGraphicSignature({required int pageIndex, required double x, required double y}) async {
    final currentRawBytes = widget.stateController.currentBytes!;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfModifierService.injectGraphicSignatureAsync(
      originalBytes: currentRawBytes,
      targetPageZeroIndexed: pageIndex,
      signatureImageBytes: widget.stateController.activeSignatureGraphicBytes!,
      coordinateX: x,
      coordinateY: y,
      password: widget.stateController.activeDocumentPassword,
    );
    if (!mounted) return;
    Navigator.pop(context);
    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
  }

  void _handleCanvasTapIntercept(PdfGestureDetails details) {
    if (widget.stateController.currentTool != ActivePdfTool.signaturePlacement) return;
    final Offset pdfPageCoordinates = details.pagePosition;
    _applyGraphicSignature(
      pageIndex: widget.stateController.activePageNumber - 1,
      x: pdfPageCoordinates.dx,
      y: pdfPageCoordinates.dy,
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: ListenableBuilder(
        listenable: widget.stateController,
        builder: (context, _) {
          final byteStream = widget.stateController.currentBytes;
          if (byteStream == null) return const Center(child: Text('// NO DATA'));

          final structuralReport = widget.stateController.securityReport;
          if (structuralReport == null) return const Center(child: CircularProgressIndicator());

          return Stack(
            children: [
              Positioned.fill(
                child: SfPdfViewer.memory(
                  byteStream,
                  // Force rebuild when bytes change by using a unique key
                  key: ValueKey(byteStream.hashCode),
                  controller: widget.stateController.pdfViewerController,
                  initialPageNumber: widget.stateController.activePageNumber,
                  interactionMode: PdfInteractionMode.pan,
                  onTap: _handleCanvasTapIntercept,
                  onPageChanged: (details) => widget.stateController.updatePageNumber(details.newPageNumber),
                ),
              ),
              // HUD Layer
              _buildTopBar(structuralReport),
              if (_showSecurityPanel) _buildSecurityPanel(structuralReport),
              if (_showToolMenu) _buildToolMenu(),
              _buildMenuToggle(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuToggle() => Positioned(
        right: 16,
        bottom: 30,
        child: FloatingActionButton(
          backgroundColor: CyberpunkTheme.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CyberpunkTheme.neonCyan),
          ),
          onPressed: () => setState(() => _showToolMenu = !_showToolMenu),
          child: Icon(
            _showToolMenu ? Icons.close : Icons.apps,
            color: CyberpunkTheme.neonCyan,
          ),
        ),
      );

  Widget _buildTopBar(PdfSecurityReport report) => Positioned(
        top: 50, left: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: CyberpunkTheme.glassDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              Text('PAGE: ${widget.stateController.activePageNumber}', style: const TextStyle(fontFamily: 'monospace')),
              IconButton(icon: const Icon(Icons.shield), onPressed: () => setState(() => _showSecurityPanel = !_showSecurityPanel)),
            ],
          ),
        ),
      );

  Widget _buildSecurityPanel(PdfSecurityReport report) => Positioned(
        top: 120, left: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: CyberpunkTheme.glassDecoration(),
          child: Column(children: [
            Text('STATUS: ${report.complianceStatus}'),
            Text('ENCRYPTED: ${report.isEncrypted}'),
          ]),
        ),
      );

  Widget _buildToolMenu() => Positioned(
        right: 16,
        bottom: 110,
        child: Column(
          children: [
            _buildToolButton(
              icon: Icons.gesture,
              onPressed: _openSignaturePad,
              isActive: widget.stateController.currentTool ==
                  ActivePdfTool.signaturePlacement,
            ),
            const SizedBox(height: 12),
            _buildToolButton(
              icon: Icons.save,
              onPressed: _executeSystemSave,
            ),
            const SizedBox(height: 12),
            _buildToolButton(
              icon: Icons.share,
              onPressed: _executeSystemShare,
            ),
          ],
        ),
      );

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: CyberpunkTheme.glassDecoration(
        borderRadius: BorderRadius.circular(12),
        borderColor: isActive
            ? CyberpunkTheme.neonCyan
            : CyberpunkTheme.neonCyan.withValues(alpha: 0.3),
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isActive ? CyberpunkTheme.neonCyan : Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _openSignaturePad() async {
    final Uint8List? signature = await showDialog<Uint8List>(
      context: context,
      builder: (context) => const SignaturePadView(),
    );

    if (signature != null) {
      widget.stateController.setupSignaturePlacement(signature);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: CyberpunkTheme.backgroundDark,
        content: Text('// SIGNATURE CAPTURED: TAP ON PDF TO POSITION',
            style: TextStyle(color: CyberpunkTheme.neonCyan)),
      ));
    }
  }
}