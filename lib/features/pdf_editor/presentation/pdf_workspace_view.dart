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
import 'interactive_text_overlay.dart';
import '../../profile/services/signature_service.dart';
// ... existing imports ...

class PdfWorkspaceView extends StatefulWidget {
// ...
}

class _PdfWorkspaceViewState extends State<PdfWorkspaceView> {
// ...
  bool _isPlacingSignature = false;
  bool _isPlacingText = false;
  ShapeType? _activeShapeType;
// ...
  @override
  Widget build(BuildContext context) {
// ...
          return Stack(
            children: [
// ...
              if (_isPlacingSignature && _pendingSignature != null)
                InteractiveSignatureOverlay(
                  imageBytes: _pendingSignature!,
                  onCancel: () => setState(() => _isPlacingSignature = false),
                  onConfirm: (pos, size) => _burnSignatureToPdf(pos, size),
                ),
              if (_isPlacingText)
                InteractiveTextOverlay(
                  onCancel: () => setState(() => _isPlacingText = false),
                  onConfirm: (text, pos, size, fontSize, color) => _burnTextToPdf(text, pos, size, fontSize, color),
                ),
              if (_isPlacingShape && _activeShapeType != null)
// ...
            ],
          );
        },
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

  Future<void> _burnTextToPdf(String text, Offset screenPos, Size size, double fontSize, Color color) async {
    if (text.isEmpty) {
      setState(() => _isPlacingText = false);
      return;
    }

    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfService.addFreeTextAnnotation(
      bytes: currentBytes,
      pageIndex: pageIndex,
      bounds: Rect.fromLTWH(screenPos.dx, screenPos.dy, size.width, size.height),
      text: text,
      fontSize: fontSize,
      textColor: sf.PdfColor(color.red, color.green, color.blue),
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    setState(() => _isPlacingText = false);
  }
// ...
et _buildOutlineDrawer() {
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
            ListTile(leading: const Icon(Icons.rotate_right_rounded), title: const Text('Rotate Page'), onTap: () { Navigator.pop(context); _handleRotation(); }),
            ListTile(leading: const Icon(Icons.lock_outline_rounded), title: const Text('Apply Password'), onTap: () { Navigator.pop(context); _handleSecurity(); }),
            ListTile(leading: const Icon(Icons.image_rounded), title: const Text('Insert Image'), onTap: () { Navigator.pop(context); _pickImageForPlacement(); }),
          ],
        ),
      ),
    );
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
            ListTile(leading: const Icon(Icons.description_rounded), title: const Text('Export Text Transcript'), onTap: () { Navigator.pop(context); _handleDataExport('TEXT'); }),
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
    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfModifierService.injectGraphicSignatureAsync(
      originalBytes: currentBytes,
      targetPageZeroIndexed: pageIndex,
      signatureImageBytes: _pendingSignature!,
      coordinateX: screenPos.dx,
      coordinateY: screenPos.dy,
      password: widget.stateController.activeDocumentPassword,
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    setState(() => _isPlacingSignature = false);
  }

  Future<void> _burnShapeToPdf(Offset screenPos, Size size) async {
    final pageIndex = widget.stateController.activePageNumber - 1;
    final currentBytes = widget.stateController.currentBytes!;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfService.addShapeAnnotation(
      bytes: currentBytes,
      pageIndex: pageIndex,
      bounds: Rect.fromLTWH(screenPos.dx, screenPos.dy, size.width, size.height),
      shapeType: _activeShapeType!.name.toUpperCase(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    setState(() => _isPlacingShape = false);
  }

  void _handleCanvasTapIntercept(PdfGestureDetails details) async {
    // Interaction handled via overlays
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

  Future<void> _handlePageDeletion() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Page?"),
        content: Text("Are you sure you want to delete page ${widget.stateController.activePageNumber}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBytes = await PdfService.deletePages(currentBytes, [widget.stateController.activePageNumber - 1]);
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
    if (result != null && result.files.single.bytes != null) {
      widget.stateController.setupImagePlacement(result.files.single.bytes!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image loaded: Tap on PDF to position')));
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
    String content = format == 'EXCEL' ? PdfService.exportToCsv(currentBytes) : PdfService.extractText(currentBytes);
    final success = await PdfModifierService.saveTextDataViaPicker(text: content, suggestedName: "Export.${format == 'EXCEL' ? 'csv' : 'txt'}");
    if (success) analyticsService.logAction("EXPORT_$format", session.fileName);
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
