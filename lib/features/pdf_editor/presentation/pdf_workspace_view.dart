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
  bool _showSecurityPanel = false; // Point 14 Panel Toggle Switch Flag
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();

  final List<List<Offset>> _activeDrawingPaths = [];
  List<Offset> _currentStrokePoints = [];

  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final bool success = await PdfModifierService.saveDocumentViaSystemPicker(
      bytes: currentBytes,
      suggestedName: 'cloudnex_sanitized_export.pdf',
    );

    if (!mounted) return;

    if (success) {
      widget.stateController.clearActiveSessionCache();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CyberpunkTheme.backgroundDark,
        content: Text(
          success ? '// EXPORT COMPLETED SUCCESSFULLY' : '// EXPORT CHANNELS ABORTED',
          style: TextStyle(color: success ? CyberpunkTheme.neonGreen : CyberpunkTheme.neonPink, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Future<void> _executeSystemShare() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    await PdfModifierService.shareDocumentViaSystemSheet(
      bytes: currentBytes,
      fileName: 'cloudnex_shared_matrix.pdf',
    );
  }

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.gesture, color: CyberpunkTheme.neonCyan),
                  title: const Text('DRAW CODESPACE VECTOR SIGNATURE', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uint8List? signatureBytes = await showDialog<Uint8List>(
                      context: context,
                      builder: (_) => const SignaturePadView(),
                    );
                    if (signatureBytes != null) {
                      widget.stateController.setupSignaturePlacement(signatureBytes);
                    }
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.image, color: CyberpunkTheme.neonGreen),
                  title: const Text('INGEST IMAGE FILE SIGNATURE MATRIX', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.single.bytes != null) {
                      widget.stateController.setupSignaturePlacement(result.files.single.bytes!);
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

  void _handleCanvasTapIntercept(TapUpDetails details) {
    if (widget.stateController.currentTool != ActivePdfTool.signaturePlacement) return;
    if (widget.stateController.activeSignatureGraphicBytes == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(details.globalPosition);
    final Offset pdfPageCoordinates = _pdfViewerKey.currentState!.convertToPdfCoordinates(localOffset);

    _applyGraphicSignature(
      pageIndex: widget.stateController.activePageNumber - 1,
      x: pdfPageCoordinates.dx,
      y: pdfPageCoordinates.dy,
    );
  }

  Future<void> _applyGraphicSignature({required int pageIndex, required double x, required double y}) async {
    final currentRawBytes = widget.stateController.currentBytes!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonPink),
        ),
      ),
    );
    
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

  Future<void> _handleTextSelectionHighlightIntercept(PdfTextSelectionChangedDetails details) async {
    if (widget.stateController.currentTool != ActivePdfTool.highlight) return;
    if (details.selectedText == null || details.selectedText!.trim().isEmpty) return;

    final String extractedTargetText = details.selectedText!;
    final int targetPageIndex = widget.stateController.activePageNumber - 1;
    final currentRawBytes = widget.stateController.currentBytes!;

    widget.stateController.pdfViewerController.clearSelection();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonGreen),
        ),
      ),
    );

    final updatedBytes = await PdfModifierService.injectTextHighlightAsync(
      originalBytes: currentRawBytes,
      targetPageZeroIndexed: targetPageIndex,
      selectedTextLine: extractedTargetText,
      password: widget.stateController.activeDocumentPassword,
    );

    if (!mounted) return;
    Navigator.pop(context);

    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
  }

  Future<void> _commitVectorDrawingToDocument() async {
    if (_activeDrawingPaths.isEmpty) return;

    final currentRawBytes = widget.stateController.currentBytes!;
    final int targetPageIndex = widget.stateController.activePageNumber - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonCyan),
        ),
      ),
    );

    final List<List<Offset>> projectedDocumentPaths = [];
    for (final List<Offset> stroke in _activeDrawingPaths) {
      final List<Offset> projectedStroke = [];
      for (final Offset localPoint in stroke) {
        final Offset documentCoordinatePoint = _pdfViewerKey.currentState!.convertToPdfCoordinates(localPoint);
        projectedStroke.add(documentCoordinatePoint);
      }
      projectedDocumentPaths.add(projectedStroke);
    }

    final updatedBytes = await PdfModifierService.injectFreehandDrawingAsync(
      originalBytes: currentRawBytes,
      targetPageZeroIndexed: targetPageIndex,
      drawingPaths: projectedDocumentPaths,
      password: widget.stateController.activeDocumentPassword,
    );

    if (!mounted) return;
    Navigator.pop(context);

    setState(() {
      _activeDrawingPaths.clear();
    });

    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
  }

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
          
          final isHighlightModeActive = activeTool == ActivePdfTool.highlight;
          final isDrawModeActive = activeTool == ActivePdfTool.draw;

          if (byteStream == null) {
            return const Center(
              child: Text(
                '// NO ACTIVE MATRIX DETECTED',
                style: TextStyle(color: CyberpunkTheme.neonPink, letterSpacing: 2.0, fontFamily: 'monospace'),
              ),
            );
          }

          // Trigger automated Point 14 architectural scan over current document bytes
          final PdfSecurityReport structuralReport = PdfModifierService.analyzeDocumentStructure(
            byteStream, 
            widget.stateController.activeDocumentPassword,
          );

          return Stack(
            children: [
              // --- BASE LAYER: PDF VIEWER ---
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
                      enableDoubleTapZooming: !isLocked,
                      interactionMode: isHighlightModeActive 
                          ? PdfInteractionMode.singleTap 
                          : (isLocked ? PdfInteractionMode.pan : PdfInteractionMode.singleTap),
                      onTextSelectionChanged: _handleTextSelectionHighlightIntercept,
                      onPageChanged: (PdfPageChangedDetails details) {
                        widget.stateController.updatePageNumber(details.newPageNumber);
                      },
                    ),
                  ),
                ),
              ),

              // --- OVERLAY LAYER: HIGH FREQUENCY DRAWING CANVAS ---
              if (isDrawModeActive)
                Positioned.fill(
                  child: SafeArea(
                    child: GestureDetector(
                      onPanStart: (DragStartDetails details) {
                        setState(() {
                          _currentStrokePoints = [details.localPosition];
                          _activeDrawingPaths.add(_currentStrokePoints);
                        });
                      },
                      onPanUpdate: (DragUpdateDetails details) {
                        setState(() {
                          _currentStrokePoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (DragEndDetails details) {
                        setState(() {
                          _currentStrokePoints = [];
                        });
                      },
                      child: CustomPaint(
                        painter: FreehandOverlayPainter(paths: _activeDrawingPaths),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),

              // --- FLOATING GLASS TOP BAR ---
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: BackdropFilter(
                    filter: CyberpunkTheme.glassBlurFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: CyberpunkTheme.glassDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        borderColor: isLocked ? _getCurrentActiveColor(activeTool).withValues(alpha: 0.4) : const Color(0x3300F0FF),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: CyberpunkTheme.textPrimary),
                            onPressed: () {
                              widget.stateController.clearActiveTool();
                              widget.stateController.clearActiveSessionCache();
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(
                            activeTool == ActivePdfTool.signaturePlacement 
                                ? 'TAP CANVAS TO PLACE EMBED' 
                                : (activeTool == ActivePdfTool.highlight 
                                    ? 'DRAG TEXT TO APPLY MARKUP' 
                                    : (activeTool == ActivePdfTool.draw ? 'SKETCH VECTOR OVERLAY CODES' : 'PAGE: ${widget.stateController.activePageNumber}')),
                            style: TextStyle(
                              color: isLocked ? _getCurrentActiveColor(activeTool) : CyberpunkTheme.neonCyan,
                              key: const ValueKey("StateDisplay"),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              if (isDrawModeActive)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: CyberpunkTheme.neonGreen),
                                  onPressed: _activeDrawingPaths.isNotEmpty ? _commitVectorDrawingToDocument : null,
                                ),
                              IconButton(
                                icon: Icon(Icons.shield, color: _showSecurityPanel ? CyberpunkTheme.neonPink : CyberpunkTheme.neonCyan),
                                onPressed: () => setState(() => _showSecurityPanel = !_showSecurityPanel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ========================================================
              // 🛡️ POINT 14 HUD: CRYPTOGRAPHIC STATUS BAR PANEL OVERLAY
              // ========================================================
              if (_showSecurityPanel)
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: BackdropFilter(
                      filter: CyberpunkTheme.glassBlurFilter,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: CyberpunkTheme.glassDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          borderColor: CyberpunkTheme.neonPink.withValues(alpha: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '// SECURE HEADERS SYSTEM ANOMALY SCANNER',
                              style: TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            _buildSecurityRow(
                              'METADATA TRACKING INTEGRITY:', 
                              structuralReport.complianceStatus == 'SECURE_COMPLIANT' ? 'SCRUBBED / CLEAN' : 'METADATA_DIRTY_RISK',
                              structuralReport.complianceStatus == 'SECURE_COMPLIANT' ? CyberpunkTheme.neonGreen : CyberpunkTheme.neonPink,
                            ),
                            _buildSecurityRow(
                              'CIPHER KEYING ENCRYPTION:', 
                              structuralReport.isEncrypted ? 'ACTIVE_PASS_LOCKED' : 'NO_CIPHER_CLEARTEXT',
                              structuralReport.isEncrypted ? CyberpunkTheme.neonPink : CyberpunkTheme.neonCyan,
                            ),
                            _buildSecurityRow(
                              'SIGNATURE BLOCK TAG:', 
                              structuralReport.authorSignature,
                              CyberpunkTheme.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // --- FLOATING TOOL STACK ---
              if (_showToolMenu)
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToolButton(Icons.brush, 'DRAW MODE', CyberpunkTheme.neonCyan, activeTool == ActivePdfTool.draw, () {
                        widget.stateController.toggleTool(ActivePdfTool.draw);
                      }),
                      const SizedBox(height: 12),
                      _buildToolButton(Icons.highlight, 'HIGHLIGHT MODE', CyberpunkTheme.neonGreen, activeTool == ActivePdfTool.highlight, () {
                        widget.stateController.toggleTool(ActivePdfTool.highlight);
                      }),
                      const SizedBox(height: 12),
                      _buildToolButton(Icons.edit, 'SIGN ENGINE CHANNELS', CyberpunkTheme.neonPink, activeTool == ActivePdfTool.signaturePlacement, () {
                        _initiateSignatureChannelSelection();
                      }),
                    ],
                  ),
                ),

              // --- FLOATING FOOTER ACTION DOCK ---
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
                        borderColor: isLocked ? _getCurrentActiveColor(activeTool).withValues(alpha: 0.5) : const Color(0x3300F0FF),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.construction, color: _showToolMenu ? CyberpunkTheme.neonPink : CyberpunkTheme.textPrimary),
                            onPressed: () => setState(() => _showToolMenu = !_showToolMenu),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save, color: CyberpunkTheme.neonCyan),
                            onPressed: _executeSystemSave,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: CyberpunkTheme.neonGreen),
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

  Widget _buildSecurityRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 10, fontFamily: 'monospace')),
          Text(value, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tip, Color color, bool isActive, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Tooltip(
        message: tip,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : CyberpunkTheme.backgroundDark.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: isActive ? 0.9 : 0.4), width: isActive ? 2 : 1),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

class FreehandOverlayPainter extends CustomPainter {
  final List<List<Offset>> paths;

  FreehandOverlayPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintConfig = Paint()
      ..color = const Color(0xCC00F0FF) 
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final List<Offset> path in paths) {
      if (path.length < 2) continue;
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], paintConfig);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FreehandOverlayPainter oldDelegate) => true;
}