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
  bool _showToolMenu = false;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey<SfPdfViewerState>();

  /// Invokes system-mediated Native File Selector for sandboxed exporting (Point 3)
  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final bool success = await PdfModifierService.saveDocumentViaSystemPicker(
      bytes: currentBytes,
      suggestedName: 'cloudnex_sanitized_export.pdf',
    );

    if (!mounted) return;

    if (success) {
      // POINT 10: Clear temporary session files since it's safely committed to persistent storage
      widget.stateController.clearActiveSessionCache();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CyberpunkTheme.backgroundDark,
        content: Text(
          success
              ? '// EXPORT COMPLETED SUCCESSFULLY'
              : '// EXPORT CHANNELS ABORTED',
          style: TextStyle(
              color:
                  success ? CyberpunkTheme.neonGreen : CyberpunkTheme.neonPink,
              fontFamily: 'monospace'),
        ),
      ),
    );
  }

  /// Streams memory data directly to device application channels via Native Share Sheets (Point 3)
  Future<void> _executeSystemShare() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    await PdfModifierService.shareDocumentViaSystemSheet(
      bytes: currentBytes,
      fileName: 'cloudnex_shared_matrix.pdf',
    );
  }

  /// Pulls up the Glassmorphic Bottom Sheet to toggle drawing pads or image ingestion matrices (Point 7)
  Future<void> _initiateSignatureChannelSelection() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: BackdropFilter(
          filter: CyberpunkTheme.glassBlurFilter,
          child: Container(
            decoration: CyberpunkTheme.glassDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.gesture, color: CyberpunkTheme.neonCyan),
                  title: const Text('DRAW CODESPACE VECTOR SIGNATURE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uint8List? signatureBytes =
                        await showDialog<Uint8List>(
                      context: context,
                      builder: (_) => const SignaturePadView(),
                    );
                    if (signatureBytes != null) {
                      widget.stateController
                          .setupSignaturePlacement(signatureBytes);
                    }
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading:
                      const Icon(Icons.image, color: CyberpunkTheme.neonGreen),
                  title: const Text('INGEST IMAGE FILE SIGNATURE MATRIX',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.single.bytes != null) {
                      widget.stateController
                          .setupSignaturePlacement(result.files.single.bytes!);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// POINT 6 TRANSLATION MATRIX: Converts screen coordinates to absolute document points
  void _handleCanvasTapIntercept(TapUpDetails details) {
    if (widget.stateController.currentTool != ActivePdfTool.signaturePlacement)
      return;
    if (widget.stateController.activeSignatureGraphicBytes == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(details.globalPosition);
    final Offset pdfPageCoordinates =
        _pdfViewerKey.currentState!.convertToPdfCoordinates(localOffset);

    _applyGraphicSignature(
      pageIndex: widget.stateController.activePageNumber - 1,
      x: pdfPageCoordinates.dx,
      y: pdfPageCoordinates.dy,
    );
  }

  /// POINT 8 CONCURRENCY HUB: dispatches computation to isolated background worker threads
  Future<void> _applyGraphicSignature(
      {required int pageIndex, required double x, required double y}) async {
    final currentRawBytes = widget.stateController.currentBytes!;

    // Non-blocking processing HUD overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonPink),
        ),
      ),
    );

    // Dispatches background processing while passing down cryptographic decryption keys (Point 9)
    final updatedBytes = await PdfModifierService.injectGraphicSignatureAsync(
      originalBytes: currentRawBytes,
      targetPageZeroIndexed: pageIndex,
      signatureImageBytes: widget.stateController.activeSignatureGraphicBytes!,
      coordinateX: x,
      coordinateY: y,
      password: widget.stateController.activeDocumentPassword,
    );

    if (!mounted) return;
    Navigator.pop(context); // Clear processing HUD

    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
  }

  /// Dynamic indicator layout mapping logic
  Color _getCurrentActiveColor(ActivePdfTool tool) {
    switch (tool) {
      case ActivePdfTool.draw:
        return CyberpunkTheme.neonCyan;
      case ActivePdfTool.highlight:
        return CyberpunkTheme.neonGreen;
      case ActivePdfTool.signaturePlacement:
        return CyberpunkTheme.neonPink;
      case ActivePdfTool.none:
        return CyberpunkTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: ListenableBuilder(
        listenable: widget.stateController,
        builder: (context, _) {
          final byteStream = widget.stateController.currentBytes;
          final activeTool = widget.stateController.currentTool;
          final isLocked = widget.stateController.isViewportLocked;

          if (byteStream == null) {
            return const Center(
              child: Text(
                '// NO ACTIVE MATRIX DETECTED',
                style: TextStyle(
                    color: CyberpunkTheme.neonPink,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace'),
              ),
            );
          }

          return Stack(
            children: [
              // --- BASE LAYER: IMMERSIVE PDF VIEWER ENGINE WITH GESTURE INTERACTION CAPTURE ---
              Positioned.fill(
                child: SafeArea(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: _handleCanvasTapIntercept,
                    child: SfPdfViewer.memory(
                      byteStream,
                      key: _pdfViewerKey,
                      controller: widget.stateController.pdfViewerController,
                      pageSpacing: 4,
                      // POINT 5 SUB-SYSTEM INTEGRATION: Freeze viewport parameters during editing
                      enableDoubleTapZooming: !isLocked,
                      interactionMode: isLocked
                          ? PdfInteractionMode.pan
                          : PdfInteractionMode.singleTap,
                      onPageChanged: (PdfPageChangedDetails details) {
                        widget.stateController
                            .updatePageNumber(details.newPageNumber);
                      },
                    ),
                  ),
                ),
              ),

              // --- FLOATING GLASS TOP BAR (Point 4 & Point 5 Layout) ---
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: BackdropFilter(
                    filter: CyberpunkTheme.glassBlurFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      decoration: CyberpunkTheme.glassDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        borderColor: isLocked
                            ? _getCurrentActiveColor(activeTool)
                                .withValues(alpha: 0.4)
                            : const Color(0x3300F0FF),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: CyberpunkTheme.textPrimary),
                            onPressed: () {
                              widget.stateController.clearActiveTool();
                              // POINT 10: Clear temporary cache buffers upon intentional back-navigation
                              widget.stateController.clearActiveSessionCache();
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(
                            activeTool == ActivePdfTool.signaturePlacement
                                ? 'TAP CANVAS TO PLACE EMBED'
                                : 'PAGE: ${widget.stateController.activePageNumber}',
                            style: TextStyle(
                              color: isLocked
                                  ? _getCurrentActiveColor(activeTool)
                                  : CyberpunkTheme.neonCyan,
                              key: const ValueKey("StateDisplay"),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.undo,
                                    color: widget.stateController.canUndo
                                        ? CyberpunkTheme.neonCyan
                                        : CyberpunkTheme.textSecondary),
                                onPressed: widget.stateController.canUndo
                                    ? widget.stateController.undo
                                    : null,
                              ),
                              IconButton(
                                icon: Icon(Icons.redo,
                                    color: widget.stateController.canRedo
                                        ? CyberpunkTheme.neonPink
                                        : CyberpunkTheme.textSecondary),
                                onPressed: widget.stateController.canRedo
                                    ? widget.stateController.redo
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- FLOATING TOOL STACK (Point 5 Responsive Thumb Reach Design) ---
              if (_showToolMenu)
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToolButton(
                          Icons.brush,
                          'DRAW MODE',
                          CyberpunkTheme.neonCyan,
                          activeTool == ActivePdfTool.draw, () {
                        widget.stateController.toggleTool(ActivePdfTool.draw);
                      }),
                      const SizedBox(height: 12),
                      _buildToolButton(
                          Icons.highlight,
                          'HIGHLIGHT MODE',
                          CyberpunkTheme.neonGreen,
                          activeTool == ActivePdfTool.highlight, () {
                        widget.stateController
                            .toggleTool(ActivePdfTool.highlight);
                      }),
                      const SizedBox(height: 12),
                      _buildToolButton(
                          Icons.edit,
                          'SIGN ENGINE CHANNELS',
                          CyberpunkTheme.neonPink,
                          activeTool == ActivePdfTool.signaturePlacement, () {
                        _initiateSignatureChannelSelection();
                      }),
                    ],
                  ),
                ),

              // --- FLOATING FOOTER ACTION DOCK (Point 4 & Point 5 Core Layout) ---
              Positioned(
                bottom: 25,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: CyberpunkTheme.glassBlurFilter,
                    child: Container(
                      height: 65,
                      decoration: CyberpunkTheme.glassDecoration(
                        borderRadius: BorderRadius.circular(30),
                        borderColor: isLocked
                            ? _getCurrentActiveColor(activeTool)
                                .withValues(alpha: 0.5)
                            : const Color(0x3300F0FF),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.construction,
                                color: _showToolMenu
                                    ? CyberpunkTheme.neonPink
                                    : CyberpunkTheme.textPrimary),
                            onPressed: () =>
                                setState(() => _showToolMenu = !_showToolMenu),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save,
                                color: CyberpunkTheme.neonCyan),
                            onPressed: _executeSystemSave,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share,
                                color: CyberpunkTheme.neonGreen),
                            onPressed: _executeSystemShare,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tip, Color color, bool isActive,
      VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Tooltip(
        message: tip,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.2)
                : CyberpunkTheme.backgroundDark.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withValues(alpha: isActive ? 0.9 : 0.4),
                width: isActive ? 2 : 1),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}