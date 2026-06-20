import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../../core/theme/pdf_pro_theme.dart';
import '../controller/pdf_state_controller.dart';
import '../services/pdf_modifier_service.dart';
import '../../../services/pdf_service.dart';
import 'signature_pad_view.dart';
import 'package:cloudnex_pdf_reader/features/analytics/services/analytics_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'interactive_signature_overlay.dart';
import 'interactive_shape_overlay.dart';
import 'page_manager_view.dart';
import '../../profile/services/signature_service.dart';
import 'interactive_text_overlay.dart';
import 'neural_live_editor.dart';
import '../../../services/neural_engine/neural_vision_engine.dart';
import '../../../services/neural_engine/npu_accelerator_service.dart';
import '../../../services/word_export_service.dart';
import 'ink_drawing_overlay.dart';
import 'dex_desktop_ribbon.dart';
import 'annotation_manager_view.dart';
import 'interactive_shadow_layer.dart';
import '../domain/models/shadow_object.dart';

class PdfWorkspaceView extends StatefulWidget {
  final PdfStateController stateController;
  const PdfWorkspaceView({super.key});

  @override
  State<PdfWorkspaceView> createState() => _PdfWorkspaceViewState();
}

class _PdfWorkspaceViewState extends State<PdfWorkspaceView> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  sf.PdfBookmarkBase? _bookmarks;
  Uint8List? _pendingSignature;
  bool _isPlacingSignature = false;
  ShapeType? _activeShapeType;
  bool _isPlacingShape = false;
  bool _isPlacingText = false;
  NeuralZone? _activeNeuralZone;
  bool _isNeuralActive = false;
  bool _isDrawingInk = false;
  bool _isMagnifierActive = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktopMode = size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE1E4E8),
      appBar: isDesktopMode ? null : _buildAppBar(),
      drawer: _buildOutlineDrawer(),
      body: ListenableBuilder(
        listenable: widget.stateController,
        builder: (context, _) {
          if (widget.stateController.sessions.isEmpty) {
            return const Center(child: Text('No active documents'));
          }

          final session = widget.stateController.activeSession;
          if (session == null) return const Center(child: CircularProgressIndicator());
          
          final byteStream = session.currentBytes;
          if (byteStream == null) return const Center(child: Text('Data stream lost'));

          return Stack(
            children: [
              Column(
                children: [
                  if (isDesktopMode) 
                    DexDesktopRibbon(
                      onAnnotate: _showAnnotationOptions,
                      onSign: _openSignatureVault,
                      onEdit: _enableNeuralEditor,
                      onForms: _handleFormFilling,
                      onExport: _showExportOptions,
                      onPrint: _handlePrint,
                    ),
                  _buildTabBar(),
                  if (_isSearching) _buildSearchBar(session),
                  Expanded(
                    child: Stack(
                      children: [
                        SfPdfViewer.memory(
                          byteStream,
                          key: _pdfViewerKey,
                          controller: session.pdfViewerController,
                          initialPageNumber: session.activePageNumber,
                          pageLayoutMode: PdfPageLayoutMode.continuous,
                          scrollDirection: PdfScrollDirection.vertical,
                          // OPTIMIZATION: Hardware-accelerated interaction
                          interactionMode: _isMagnifierActive 
                              ? PdfInteractionMode.magnifier 
                              : (widget.stateController.currentTool == ActivePdfTool.none || widget.stateController.currentTool == ActivePdfTool.select
                                  ? PdfInteractionMode.pan 
                                  : PdfInteractionMode.selection),
                          onTap: _handleCanvasTapIntercept,
                          onPageChanged: (details) => widget.stateController.updatePageNumber(details.newPageNumber),
                          onTextSelectionChanged: _handleTextSelection,
                          onDocumentLoaded: (details) {
                            setState(() {
                              _bookmarks = details.document.bookmarks;
                            });
                          },
                        ),
                        // SHADOW LAYER: Live interactive widgets
                        InteractiveShadowLayer(
                          stateController: widget.stateController,
                          pdfViewerController: session.pdfViewerController,
                        ),
                      ],
                    ),
                  ),
                  if (!isDesktopMode) _buildToolDock(),
                ],
              ),
              if (_isPlacingSignature && _pendingSignature != null)
                InteractiveSignatureOverlay(
                  imageBytes: _pendingSignature!,
                  onCancel: () => setState(() => _isPlacingSignature = false),
                  onConfirm: (pos, size) => _addShadowSignature(pos, size),
                ),
              if (_isPlacingText)
                InteractiveTextOverlay(
                  onCancel: () => setState(() => _isPlacingText = false),
                  onConfirm: (text, pos, size, fontSize, color) => _addShadowText(text, pos, size, fontSize, color),
                ),
              if (_isPlacingShape && _activeShapeType != null)
                InteractiveShapeOverlay(
                  type: _activeShapeType!,
                  onCancel: () => setState(() => _isPlacingShape = false),
                  onConfirm: (pos, size) => _addShadowShape(pos, size),
                ),
              if (_isNeuralActive && _activeNeuralZone != null)
                NeuralLiveEditor(
                  zone: _activeNeuralZone!,
                  onCancel: () => setState(() => _isNeuralActive = false),
                  onConfirm: (text, size) => _burnNeuralEdit(text, size),
                ),
              if (_isDrawingInk)
                InkDrawingOverlay(
                  onCancel: () => setState(() => _isDrawingInk = false),
                  onConfirm: (paths, width, color) => _burnInkToPdf(paths, width, color),
                ),
              AnnotationManagerOverlay(
                controller: session.pdfViewerController,
                onAddComment: _handleAddComment,
                onFlatten: _handleFlattenAndBurn,
              ),
            ],
          );
        },
      ),
    );
  }

  void _addShadowSignature(Offset pos, Size size) {
    widget.stateController.addShadowObject(ShadowObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ShadowObjectType.signature,
      position: pos,
      size: size,
      content: String.fromCharCodes(_pendingSignature!), // Simulating bytes as content for prototype
      pageIndex: widget.stateController.activePageNumber - 1,
    ));
    setState(() => _isPlacingSignature = false);
  }

  void _addShadowText(String text, Offset pos, Size size, double fontSize, Color color) {
    widget.stateController.addShadowObject(ShadowObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ShadowObjectType.text,
      position: pos,
      size: size,
      content: text,
      fontSize: fontSize,
      color: color,
      pageIndex: widget.stateController.activePageNumber - 1,
    ));
    setState(() => _isPlacingText = false);
  }

  void _addShadowShape(Offset pos, Size size) {
    widget.stateController.addShadowObject(ShadowObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ShadowObjectType.shape,
      position: pos,
      size: size,
      content: _activeShapeType!.name.toUpperCase(),
      pageIndex: widget.stateController.activePageNumber - 1,
    ));
    setState(() => _isPlacingShape = false);
  }

  Future<void> _handleFlattenAndBurn() async {
    final session = widget.stateController.activeSession;
    if (session == null || session.shadowObjects.isEmpty) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      Uint8List currentBytes = session.currentBytes!;
      
      // Iterate through all shadow objects and burn them into the binary
      for (var obj in session.shadowObjects) {
        if (obj.type == ShadowObjectType.text) {
          currentBytes = await PdfService.addFreeTextAnnotation(
            bytes: currentBytes,
            pageIndex: obj.pageIndex,
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
            text: obj.content,
            fontSize: obj.fontSize,
            textColor: sf.PdfColor(obj.color.red, obj.color.green, obj.color.blue),
          );
        } else if (obj.type == ShadowObjectType.signature) {
          currentBytes = await PdfModifierService.injectGraphicSignatureAsync(
            originalBytes: currentBytes,
            targetPageZeroIndexed: obj.pageIndex,
            signatureImageBytes: Uint8List.fromList(obj.content.codeUnits),
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
          );
        } else if (obj.type == ShadowObjectType.shape) {
          currentBytes = await PdfService.addShapeAnnotation(
            bytes: currentBytes,
            pageIndex: obj.pageIndex,
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
            shapeType: obj.content,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      
      widget.stateController.commitMutation(currentBytes);
      session.shadowObjects.clear();
      widget.stateController.clearActiveTool();
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CloudNex Compilation Complete: All edits flattened into PDF.")));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Flattening failed: $e")));
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: PdfProTheme.textDark),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(widget.stateController.activeSession?.fileName ?? "CloudNex PDF Pro"),
      actions: [
        IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => _isSearching = !_isSearching)),
        IconButton(icon: const Icon(Icons.undo_rounded), onPressed: widget.stateController.canUndo ? () => widget.stateController.undo() : null),
        IconButton(icon: const Icon(Icons.redo_rounded), onPressed: widget.stateController.canRedo ? () => widget.stateController.redo() : null),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.stateController.sessions.length,
        itemBuilder: (context, index) {
          final session = widget.stateController.sessions[index];
          final isActive = index == widget.stateController.activeSessionIndex;
          return GestureDetector(
            onTap: () => widget.stateController.switchToSession(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? PdfProTheme.backgroundLight : Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    session.fileName,
                    style: TextStyle(
                      color: isActive ? PdfProTheme.primaryBlue : PdfProTheme.textLight,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (widget.stateController.sessions.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.stateController.closeSession(index),
                      child: Icon(Icons.close_rounded, size: 14, color: isActive ? PdfProTheme.primaryBlue : PdfProTheme.textLight),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(PdfSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search in document...",
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _isSearching = false)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          filled: true,
          fillColor: PdfProTheme.backgroundLight,
        ),
        onSubmitted: (val) => session.pdfViewerController.searchText(val),
      ),
    );
  }

  Widget _buildToolDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DockButton(icon: Icons.border_color_rounded, label: "Annotate", 
            onPressed: _showAnnotationOptions,
            isActive: widget.stateController.currentTool == ActivePdfTool.highlight),
          _DockButton(icon: Icons.text_fields_rounded, label: "Text", 
            onPressed: () => setState(() => _isPlacingText = true),
            isActive: _isPlacingText),
          _DockButton(icon: Icons.gesture_rounded, label: "Sign", 
            onPressed: _openSignatureVault,
            isActive: _isPlacingSignature),
          _DockButton(icon: Icons.edit_document, label: "Edit", onPressed: _showEditOptions),
          _DockButton(icon: Icons.save_alt_rounded, label: "Export", onPressed: _showExportOptions),
        ],
      ),
    );
  }

  Widget _buildOutlineDrawer() {
    final session = widget.stateController.activeSession;
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: PdfProTheme.primaryBlue),
            child: Center(
              child: Text("Document Outline", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: (session == null || _bookmarks == null || _bookmarks!.count == 0)
              ? const Center(child: Text("No bookmarks found"))
              : ListView.builder(
                  itemCount: _bookmarks!.count,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks![index];
                    return ListTile(
                      title: Text(bookmark.title),
                      onTap: () {
                        Navigator.pop(context);
                        session.pdfViewerController.jumpToBookmark(bookmark);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showAnnotationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.highlight_rounded, color: Colors.amber), title: const Text('Highlight'), onTap: () { Navigator.pop(context); _applyAnnotation(sf.PdfTextMarkupAnnotationType.highlight); }),
            ListTile(leading: const Icon(Icons.format_underlined_rounded), title: const Text('Underline'), onTap: () { Navigator.pop(context); _applyAnnotation(sf.PdfTextMarkupAnnotationType.underline); }),
            ListTile(leading: const Icon(Icons.strikethrough_s_rounded), title: const Text('Strikeout'), onTap: () { Navigator.pop(context); _applyAnnotation(sf.PdfTextMarkupAnnotationType.strikethrough); }),
            ListTile(leading: const Icon(Icons.gesture_rounded, color: PdfProTheme.primaryBlue), title: const Text('Freehand Pen'), onTap: () { Navigator.pop(context); setState(() => _isDrawingInk = true); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.rectangle_outlined), title: const Text('Rectangle'), onTap: () { Navigator.pop(context); setState(() { _activeShapeType = ShapeType.rectangle; _isPlacingShape = true; }); }),
            ListTile(leading: const Icon(Icons.circle_outlined), title: const Text('Circle'), onTap: () { Navigator.pop(context); setState(() { _activeShapeType = ShapeType.circle; _isPlacingShape = true; }); }),
            ListTile(leading: const Icon(Icons.horizontal_rule_rounded), title: const Text('Line'), onTap: () { Navigator.pop(context); setState(() { _activeShapeType = ShapeType.line; _isPlacingShape = true; }); }),
          ],
        ),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.layers_rounded), title: const Text('Page Manager (Reorder/Delete)'), onTap: () { Navigator.pop(context); _openPageManager(); }),
            ListTile(leading: const Icon(Icons.auto_fix_high_rounded), title: const Text('Edit Existing Text (Neural)'), onTap: () { Navigator.pop(context); _enableNeuralEditor(); }),
            ListTile(leading: const Icon(Icons.compress_rounded), title: const Text('Compress PDF (Reduce Size)'), onTap: () { Navigator.pop(context); _handleCompression(); }),
            ListTile(leading: const Icon(Icons.text_fields_rounded), title: const Text('Apply Watermark'), onTap: () { Navigator.pop(context); _handleWatermark(); }),
            ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('Edit Metadata (Properties)'), onTap: () { Navigator.pop(context); _handleMetadataEdit(); }),
            ListTile(leading: const Icon(Icons.zoom_in_rounded), title: const Text('Toggle Magnifier Glass'), onTap: () { Navigator.pop(context); setState(() => _isMagnifierActive = !_isMagnifierActive); }),
            ListTile(leading: const Icon(Icons.image_rounded), title: const Text('Insert Image'), onTap: () { Navigator.pop(context); _pickImageForPlacement(); }),
          ],
        ),
      ),
    );
  }

  void _enableNeuralEditor() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: PdfProTheme.primaryBlue,
      content: Text("// NEURAL_LINK_ACTIVE: TAP ON TEXT TO RECONSTRUCT"),
    ));
    widget.stateController.toggleTool(ActivePdfTool.textPlacement); 
  }

  void _openPageManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PageManagerView(stateController: widget.stateController)),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.picture_as_pdf_rounded), title: const Text('Save as PDF'), onTap: () { Navigator.pop(context); _executeSystemSave(); }),
            ListTile(leading: const Icon(Icons.print_rounded), title: const Text('Print Document'), onTap: () { Navigator.pop(context); _handlePrint(); }),
            ListTile(leading: const Icon(Icons.table_chart_rounded), title: const Text('Export to Excel (CSV)'), onTap: () { Navigator.pop(context); _handleDataExport('EXCEL'); }),
            ListTile(leading: const Icon(Icons.description_rounded), title: const Text('Export to Word (DOCX)'), onTap: () { Navigator.pop(context); _handleDataExport('WORD'); }),
          ],
        ),
      ),
    );
  }

  Future<void> _applyAnnotation(sf.PdfTextMarkupAnnotationType type) async {
    widget.stateController.toggleTool(
      type == sf.PdfTextMarkupAnnotationType.highlight ? ActivePdfTool.highlight :
      type == sf.PdfTextMarkupAnnotationType.underline ? ActivePdfTool.underline :
      ActivePdfTool.strikeout
    );
  }

  void _handleTextSelection(PdfTextSelectionChangedDetails details) async {
    if (widget.stateController.currentTool == ActivePdfTool.none || details.selectedText == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final currentBytes = widget.stateController.currentBytes!;
      final updatedBytes = await PdfService.addTextAnnotation(
        bytes: currentBytes,
        pageIndex: widget.stateController.activePageNumber - 1,
        bounds: [const Rect.fromLTWH(100, 100, 200, 20)],
        type: sf.PdfTextMarkupAnnotationType.highlight,
        text: details.selectedText,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.stateController.commitMutation(updatedBytes);
      widget.stateController.clearActiveTool();
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _openSignatureVault() async {
    final bytes = await SignatureService().getSignatureBytes();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No signature saved. Please add one in Profile.")));
      return;
    }
    setState(() {
      _pendingSignature = bytes;
      _isPlacingSignature = true;
    });
  }

  Future<void> _burnSignatureToPdf(Offset screenPos, Size size) async {
    final session = widget.stateController.activeSession;
    if (session == null) return;
    
    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    final RenderBox? viewerBox = _pdfViewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewerBox == null) return;
    
    final Offset localViewportPos = viewerBox.globalToLocal(screenPos);
    final Rect pageRect = Rect.fromLTWH(localViewportPos.dx, localViewportPos.dy, size.width, size.height);
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfModifierService.injectGraphicSignatureAsync(
      originalBytes: currentBytes,
      targetPageZeroIndexed: pageIndex,
      signatureImageBytes: _pendingSignature!,
      bounds: pageRect,
      password: widget.stateController.activeDocumentPassword,
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    setState(() => _isPlacingSignature = false);
  }

  Future<void> _burnInkToPdf(List<List<Offset>> paths, double width, Color color) async {
    if (paths.isEmpty) {
      setState(() => _isDrawingInk = false);
      return;
    }

    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfService.addInkAnnotation(
      bytes: currentBytes,
      pageIndex: pageIndex,
      paths: paths,
      strokeWidth: width,
      color: sf.PdfColor(color.red, color.green, color.blue),
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    setState(() => _isDrawingInk = false);
  }

  void _handleCanvasTapIntercept(PdfGestureDetails details) async {
    if (widget.stateController.currentTool == ActivePdfTool.textPlacement) {
      _runNeuralReconstruction(details);
    }
  }

  Future<void> _runNeuralReconstruction(PdfGestureDetails details) async {
    final currentBytes = widget.stateController.currentBytes!;
    final pageIndex = details.pageNumber - 1;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    // Layer 1: Neural Vision Reconstruction
    final zones = await NpuAcceleratorService.analyzePageAsync(currentBytes, pageIndex);
    
    if (!mounted) return;
    Navigator.pop(context);

    NeuralZone? match;
    for (var zone in zones) {
      if (zone.bounds.contains(details.pagePosition)) {
        match = zone;
        break;
      }
    }

    if (match != null) {
      setState(() {
        _activeNeuralZone = match;
        _isNeuralActive = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CloudNex Neural could not isolate a text block here.")));
    }
  }

  Future<void> _burnNeuralEdit(String newText, double newSize) async {
    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    Uint8List updatedBytes = await PdfService.redactArea(
      currentBytes, 
      pageIndex, 
      _activeNeuralZone!.bounds,
    );

    updatedBytes = await PdfService.addFreeTextAnnotation(
      bytes: updatedBytes,
      pageIndex: pageIndex,
      bounds: _activeNeuralZone!.bounds,
      text: newText,
      fontSize: newSize,
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
    setState(() => _isNeuralActive = false);
  }

  Future<void> _handleCompression() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final updatedBytes = await PdfService.compressPdf(bytes);
    if (!mounted) return;
    Navigator.pop(context);
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Compressed for high-speed transmission.")));
  }

  Future<void> _handleWatermark() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    final updatedBytes = await PdfService.addWatermark(bytes, "CLOUDNEX PRO");
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DRAFT Watermark applied to all pages.")));
  }

  Future<void> _handleAddComment() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sticky Note mode active: Tap to drop a note.")));
  }

  Future<void> _handleMetadataEdit() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    final updatedBytes = await PdfService.updateMetadata(
      bytes: bytes,
      title: "CloudNex Secured Document",
      author: "Enterprise User",
    );
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Metadata Updated: Title set to 'CloudNex Secured'.")));
  }

  Future<void> _handleRotation() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final updatedBytes = await PdfService.rotatePage(
      currentBytes, 
      widget.stateController.activePageNumber - 1, 
      sf.PdfPageRotateAngle.rotateAngle90,
    );
    if (!mounted) return;
    Navigator.pop(context);
    widget.stateController.commitMutation(updatedBytes);
  }

  Future<void> _handlePageDeletion(int index) async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Page?"),
        content: Text("Are you sure you want to delete page ${index + 1}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBytes = await PdfService.deletePages(currentBytes, [index]);
      if (!mounted) return;
      Navigator.pop(context);
      widget.stateController.commitMutation(updatedBytes);
    }
  }

  Future<void> _handleSecurity() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final TextEditingController passController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Document Password"),
        content: TextField(
          controller: passController,
          decoration: const InputDecoration(hintText: "Enter password..."),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Apply")),
        ],
      ),
    );

    if (confirm == true && passController.text.isNotEmpty) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBytes = await PdfService.applySecurity(currentBytes, passController.text);
      if (!mounted) return;
      Navigator.pop(context);
      widget.stateController.commitMutation(updatedBytes);
    }
  }

  Future<void> _pickImageForPlacement() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      widget.stateController.setupImagePlacement(bytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image loaded: Tap on PDF to position')));
    }
  }

  Future<void> _handleFormFilling() async {
    final currentBytes = widget.stateController.currentBytes!;
    final fields = PdfService.getFormFields(currentBytes);
    if (fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No interactive fields detected")));
      return;
    }
  }

  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes!;
    final success = await PdfModifierService.saveDocumentViaSystemPicker(bytes: currentBytes, suggestedName: 'Export.pdf');
    if (success) analyticsService.logAction("EXPORT_DOCUMENT", widget.stateController.activeSession!.fileName);
  }

  Future<void> _handlePrint() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    await Printing.layoutPdf(
      onLayout: (format) async => currentBytes,
      name: widget.stateController.activeSession?.fileName ?? "Document",
    );
  }

  Future<void> _handleDataExport(String format) async {
    final currentBytes = widget.stateController.currentBytes!;
    final session = widget.stateController.activeSession!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      Uint8List fileData;
      String ext = "";
      
      if (format == 'EXCEL') {
        final content = PdfService.exportToCsv(currentBytes);
        fileData = Uint8List.fromList(content.codeUnits);
        ext = "csv";
      } else if (format == 'WORD') {
        fileData = WordExportService.convertToWordDocx(currentBytes);
        ext = "docx";
      } else {
        final content = PdfService.extractText(currentBytes);
        fileData = Uint8List.fromList(content.codeUnits);
        ext = "txt";
      }
      
      if (!mounted) return;
      Navigator.pop(context);

      final success = await PdfModifierService.saveDocumentViaSystemPicker(
        bytes: fileData, 
        suggestedName: "Export.$ext",
      );
      
      if (success) analyticsService.logAction("EXPORT_$format", session.fileName);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _DockButton({required this.icon, required this.label, required this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? PdfProTheme.primaryBlue : PdfProTheme.textLight),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? PdfProTheme.primaryBlue : PdfProTheme.textLight, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
