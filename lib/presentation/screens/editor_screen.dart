import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/theme/pdf_pro_theme.dart';
import '../../core/state/app_state.dart';
import '../../engine/edit/edit_engine.dart';
import '../../engine/render/render_engine.dart';
import '../../core/state/analytics_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../widgets/signature_overlay.dart';
import '../widgets/shape_overlay.dart';
import 'page_manager_screen.dart';
import '../../engine/edit/signature_service.dart';
import '../widgets/text_overlay.dart';
import '../widgets/neural_editor.dart';
import '../../ai/pipeline/vision_pipeline.dart';
import '../../storage/export/word_exporter.dart';
import '../widgets/ink_drawing_overlay.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/annotation_tools.dart';
import '../widgets/overlay_layer.dart';
import '../../storage/graph/overlay_model.dart';

class EditorScreen extends StatefulWidget {
  final AppState stateController;
  const EditorScreen({super.key, required this.stateController});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final bool isDesktopMode = size.width > 900;
    final isEditMode = widget.stateController.isEditMode;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isEditMode ? const Color(0xFF1E1F22) : const Color(0xFF2C2E33), 
      appBar: _buildAppBar(isDesktopMode),
      drawer: _buildOutlineDrawer(),
      body: _buildLayeredBody(isDesktopMode),
    );
  }

  /// NEW: Physical separation of View and Edit layers
  Widget _buildLayeredBody(bool isDesktopMode) {
    final session = widget.stateController.activeSession;
    if (session == null) {
      return const Center(child: Text('No active document', style: TextStyle(color: Colors.white70)));
    }
    
    final byteStream = session.currentBytes;
    if (byteStream == null) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          children: [
            // Edit Workspace Top Bar
            if (widget.stateController.isEditMode) 
              _buildEditWorkspaceHeader(isDesktopMode),
            
            if (_isSearching) _buildSearchBar(session),
            
            Expanded(
              child: Stack(
                children: [
                  // BASE LAYER: Always the Viewer
                  RepaintBoundary(
                    child: SfPdfViewer.memory(
                      byteStream,
                      key: _pdfViewerKey,
                      controller: session.pdfViewerController,
                      initialPageNumber: session.activePageNumber,
                      pageLayoutMode: PdfPageLayoutMode.continuous,
                      scrollDirection: PdfScrollDirection.vertical,
                      enableTextSelection: widget.stateController.isEditMode,
                      enableDocumentLinkAnnotation: true,
                      interactionMode: widget.stateController.isEditMode 
                              ? PdfInteractionMode.selection 
                              : PdfInteractionMode.pan,
                      onTap: _handleCanvasTapIntercept,
                      onPageChanged: (details) => widget.stateController.updatePageNumber(details.newPageNumber),
                      onTextSelectionChanged: _handleTextSelection,
                      onDocumentLoaded: (details) {
                        setState(() {
                          _bookmarks = details.document.bookmarks;
                        });
                      },
                    ),
                  ),

                  // EDIT LAYER: Only mounted when Editing
                  if (widget.stateController.isEditMode)
                    _buildInteractiveEditLayer(session),
                  
                  if (_isMagnifierActive)
                    _buildMagnifierLens(),
                ],
              ),
            ),
            
            // View Mode Bottom Bar (Clean)
            if (!widget.stateController.isEditMode)
               _buildReadingModeFooter(),
          ],
        ),
        
        // MODAL TOOLS: Only active when a tool is selected
        if (widget.stateController.isEditMode)
           _buildModalToolOverlays(session),
      ],
    );
  }

  Widget _buildEditWorkspaceHeader(bool isDesktopMode) {
    return Container(
      color: Colors.white,
      child: FloatingToolbar(
        onAnnotate: _showAnnotationOptions,
        onSign: _openSignatureVault,
        onEdit: _enableNeuralEditor,
        onForms: _handleFormFilling,
        onExport: _showExportOptions,
        onPrint: _handlePrint,
      ),
    );
  }

  Widget _buildInteractiveEditLayer(PdfSession session) {
    return ListenableBuilder(
      listenable: widget.stateController,
      builder: (context, _) => OverlayLayer(
        stateController: widget.stateController,
        pdfViewerController: session.pdfViewerController,
      ),
    );
  }

  Widget _buildReadingModeFooter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.list_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          Text(
            "Page ${widget.stateController.activePageNumber}",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _showExportOptions),
        ],
      ),
    );
  }

  Widget _buildModalToolOverlays(PdfSession session) {
    return ListenableBuilder(
      listenable: widget.stateController,
      builder: (context, _) {
        return Stack(
          children: [
            if (_isPlacingSignature && _pendingSignature != null)
              SignatureOverlay(
                imageBytes: _pendingSignature!,
                onCancel: () => setState(() => _isPlacingSignature = false),
                onConfirm: (pos, size) => _addShadowSignature(pos, size),
              ),
            if (_isPlacingText)
              TextOverlay(
                onCancel: () => setState(() => _isPlacingText = false),
                onConfirm: (text, pos, size, fontSize, color) => _addShadowText(text, pos, size, fontSize, color),
              ),
            if (_isPlacingShape && _activeShapeType != null)
              ShapeOverlay(
                type: _activeShapeType!,
                onCancel: () => setState(() => _isPlacingShape = false),
                onConfirm: (pos, size) => _addShadowShape(pos, size),
              ),
            if (_isNeuralActive && _activeNeuralZone != null)
              NeuralEditor(
                zone: _activeNeuralZone!,
                onCancel: () => setState(() => _isNeuralActive = false),
                onConfirm: (text, size) => _burnNeuralEdit(text, size),
              ),
            if (_isDrawingInk)
              InkDrawingOverlay(
                onCancel: () => setState(() => _isDrawingInk = false),
                onConfirm: (paths, width, color) => _burnInkToPdf(paths, width, color),
              ),
            AnnotationTools(
              controller: session.pdfViewerController,
              onAddComment: _handleAddComment,
              onFlatten: _handleFlattenAndBurn,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMagnifierLens() {
    return Positioned(
      top: 100,
      left: 100,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PdfProTheme.primaryBlue, width: 3),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
          color: Colors.white,
        ),
        child: const Center(child: Icon(Icons.zoom_in_rounded, size: 40, color: PdfProTheme.primaryBlue)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktopMode) {
    if (isDesktopMode && widget.stateController.isEditMode) {
       return const PreferredSize(preferredSize: Size.zero, child: SizedBox.shrink());
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: PdfProTheme.textDark),
        onPressed: () {
          widget.stateController.closeSession();
          Navigator.pop(context);
        },
      ),
      title: Text(
        widget.stateController.activeSession?.fileName ?? "CloudNex PDF Pro",
        style: const TextStyle(fontSize: 14, color: PdfProTheme.textDark, fontWeight: FontWeight.bold),
      ),
      actions: [
        _buildModeToggle(),
        IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => _isSearching = !_isSearching)),
        if (widget.stateController.isEditMode) ...[
          IconButton(icon: const Icon(Icons.undo_rounded), onPressed: widget.stateController.canUndo ? () => widget.stateController.undo() : null),
          IconButton(icon: const Icon(Icons.redo_rounded), onPressed: widget.stateController.canRedo ? () => widget.stateController.redo() : null),
        ],
        const SizedBox(width: 8),
      ],
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
    // Only show dock in Edit mode
    if (!widget.stateController.isEditMode) return const SizedBox.shrink();

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
      MaterialPageRoute(builder: (context) => PageManagerScreen(stateController: widget.stateController)),
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
      final updatedBytes = await RenderEngine.addTextAnnotation(
        bytes: currentBytes,
        pageIndex: widget.stateController.activePageNumber - 1,
        bounds: [const Rect.fromLTWH(100, 100, 200, 20)], 
        type: sf.PdfTextMarkupAnnotationType.highlight, 
        text: details.selectedText,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.stateController.commitMutation(updatedBytes);
      widget.stateController.clearActiveTool();
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _openSignatureVault() async {
    final bytes = await SignatureService().getSignatureBytes();
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No signature saved. Please add one in Profile.")));
      return;
    }
    setState(() {
      _pendingSignature = bytes;
      _isPlacingSignature = true;
    });
  }

  void _addShadowSignature(Offset pos, Size size) {
    widget.stateController.addShadowObject(ShadowObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ShadowObjectType.signature,
      position: pos,
      size: size,
      content: String.fromCharCodes(_pendingSignature!), 
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
      
      for (var obj in session.shadowObjects) {
        if (obj.type == ShadowObjectType.text) {
          currentBytes = await RenderEngine.addFreeTextAnnotation(
            bytes: currentBytes,
            pageIndex: obj.pageIndex,
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
            text: obj.content,
            fontSize: obj.fontSize,
            textColor: sf.PdfColor(
              (obj.color.r * 255).round().clamp(0, 255),
              (obj.color.g * 255).round().clamp(0, 255),
              (obj.color.b * 255).round().clamp(0, 255),
            ),
          );
        } else if (obj.type == ShadowObjectType.signature) {
          currentBytes = await EditEngine.injectGraphicSignatureAsync(
            originalBytes: currentBytes,
            targetPageZeroIndexed: obj.pageIndex,
            signatureImageBytes: Uint8List.fromList(obj.content.codeUnits),
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
          );
        } else if (obj.type == ShadowObjectType.shape) {
          currentBytes = await RenderEngine.addShapeAnnotation(
            bytes: currentBytes,
            pageIndex: obj.pageIndex,
            bounds: Rect.fromLTWH(obj.position.dx, obj.position.dy, obj.size.width, obj.size.height),
            shapeType: obj.content,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      
      widget.stateController.commitMutation(currentBytes);
      session.shadowObjects.clear();
      widget.stateController.clearActiveTool();
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CloudNex Compilation Complete: All edits flattened into PDF.")));
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Flattening failed: $e")));
    }
  }

  Future<void> _burnInkToPdf(List<List<Offset>> paths, double width, Color color) async {
    if (paths.isEmpty) {
      setState(() => _isDrawingInk = false);
      return;
    }

    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await RenderEngine.addInkAnnotation(
      bytes: currentBytes,
      pageIndex: pageIndex,
      paths: paths,
      strokeWidth: width,
      color: sf.PdfColor(
        (color.r * 255).round().clamp(0, 255),
        (color.g * 255).round().clamp(0, 255),
        (color.b * 255).round().clamp(0, 255),
      ),
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    
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

    final zones = VisionPipeline.scanPage(currentBytes, pageIndex);
    
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

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

    Uint8List updatedBytes = await RenderEngine.redactArea(
      currentBytes, 
      pageIndex, 
      _activeNeuralZone!.bounds,
    );

    updatedBytes = await RenderEngine.addFreeTextAnnotation(
      bytes: updatedBytes,
      pageIndex: pageIndex,
      bounds: _activeNeuralZone!.bounds,
      text: newText,
      fontSize: newSize,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    
    widget.stateController.commitMutation(updatedBytes);
    widget.stateController.clearActiveTool();
    setState(() => _isNeuralActive = false);
  }

  Future<void> _handleCompression() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final updatedBytes = await RenderEngine.compressPdf(bytes);
    if (!mounted) return;
    Navigator.pop(context);
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Compressed for high-speed transmission.")));
  }

  Future<void> _handleWatermark() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    final updatedBytes = await RenderEngine.addWatermark(bytes, "CLOUDNEX PRO");
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DRAFT Watermark applied to all pages.")));
  }

  Future<void> _handleAddComment() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sticky Note mode active: Tap to drop a note.")));
  }

  Future<void> _handleMetadataEdit() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    final updatedBytes = await RenderEngine.updateMetadata(
      bytes: bytes,
      title: "CloudNex Secured Document",
      author: "Enterprise User",
    );
    widget.stateController.commitMutation(updatedBytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Metadata Updated: Title set to 'CloudNex Secured'.")));
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
    final fields = RenderEngine.getFormFields(currentBytes);
    if (fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No interactive fields detected")));
      return;
    }
  }

  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes!;
    final success = await EditEngine.saveDocumentViaSystemPicker(bytes: currentBytes, suggestedName: 'Export.pdf');
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
        final content = RenderEngine.exportToCsv(currentBytes);
        fileData = Uint8List.fromList(content.codeUnits);
        ext = "csv";
      } else if (format == 'WORD') {
        fileData = WordExporter.convertToWordDocx(currentBytes);
        ext = "docx";
      } else {
        final content = RenderEngine.extractText(currentBytes);
        fileData = Uint8List.fromList(content.codeUnits);
        ext = "txt";
      }
      
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final success = await EditEngine.saveDocumentViaSystemPicker(
        bytes: fileData, 
        suggestedName: "Export.$ext",
      );
      
      if (success) analyticsService.logAction("EXPORT_$format", session.fileName);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  void _burnSignatureToPdf(Offset screenPos, Size size) {}

  Widget _buildModeToggle() {
    final isEdit = widget.stateController.isEditMode;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isEdit ? PdfProTheme.primaryBlue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => widget.stateController.toggleEditMode(),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.visibility_rounded,
                size: 18,
                color: isEdit ? Colors.white : PdfProTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                isEdit ? "EDIT" : "VIEW",
                style: TextStyle(
                  color: isEdit ? Colors.white : PdfProTheme.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
