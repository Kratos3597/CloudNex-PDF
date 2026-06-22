import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as px;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/theme/pdf_pro_theme.dart';
import '../../core/state/app_state.dart';
import '../../engine/render/render_engine.dart';

class PageManagerScreen extends StatefulWidget {
  final AppState stateController;
  const PageManagerScreen({super.key, required this.stateController});

  @override
  State<PageManagerScreen> createState() => _PageManagerScreenState();
}

class _PageManagerScreenState extends State<PageManagerScreen> {
  // DEFERRED COMMIT MODEL
  List<int> _pageOrder = [];
  List<Uint8List> _pagePreviews = [];
  bool _isLoading = true;
  bool _isDisposed = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _generatePreviews();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _generatePreviews() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    try {
      final doc = await px.PdfDocument.openData(bytes);
      final List<Uint8List> previews = [];
      final List<int> order = [];
      
      for (int i = 1; i <= doc.pagesCount; i++) {
        if (_isDisposed) break;
        
        final page = await doc.getPage(i);
        final pageImage = await page.render(width: 250, height: 350);
        if (pageImage != null) {
          previews.add(pageImage.bytes);
          order.add(i - 1);
        }
        await page.close();
      }
      
      await doc.close();
      
      if (!_isDisposed) {
        setState(() {
          _pagePreviews = previews;
          _pageOrder = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error generating previews: $e");
      if (!_isDisposed) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Organize Pages"),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _handleCommit,
              child: const Text("Apply Changes", style: TextStyle(fontWeight: FontWeight.bold, color: PdfProTheme.primaryBlue)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_hasChanges ? "Cancel" : "Done"),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              padding: const EdgeInsets.all(16),
              onReorder: _handleReorder,
              children: List.generate(_pageOrder.length, (index) {
                final originalIndex = _pageOrder[index];
                return _buildPageCard(index, originalIndex);
              }),
            ),
    );
  }

  Widget _buildPageCard(int currentIndex, int originalIndex) {
    return Card(
      key: ValueKey('page_$originalIndex'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Image.memory(_pagePreviews[originalIndex], fit: BoxFit.cover),
        ),
        title: Text("Page ${currentIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Original Index: ${originalIndex + 1}", style: const TextStyle(fontSize: 10)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: PdfProTheme.errorRed),
              onPressed: () => _deletePage(currentIndex),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final int item = _pageOrder.removeAt(oldIndex);
      _pageOrder.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _deletePage(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Page?"),
        content: const Text("This will mark the page for deletion."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _pageOrder.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  Future<void> _handleCommit() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updatedBytes = await _applyBulkChanges(currentBytes);
      
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      
      widget.stateController.commitMutation(updatedBytes);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to apply changes: $e")));
    }
  }

  Future<Uint8List> _applyBulkChanges(Uint8List bytes) async {
    return await reorderPagesSequentially(bytes, _pageOrder);
  }

  static Future<Uint8List> reorderPagesSequentially(Uint8List bytes, List<int> order) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfDocument newDoc = sf.PdfDocument();
    try {
      for (int i in order) {
        newDoc.pages.add().graphics.drawPdfTemplate(
          document.pages[i].createTemplate(),
          const Offset(0, 0),
        );
      }
      final List<int> savedBytes = await newDoc.save();
      return Uint8List.fromList(savedBytes);
    } finally {
      document.dispose();
      newDoc.dispose();
    }
  }
}
