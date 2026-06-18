import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../ai_assistant/presentation/ai_panel.dart';
import '../../../services/pdf_service.dart';

enum PdfTool { none, textOverlay }

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  
  bool _showAiPanel = false;
  PdfTool _activeTool = PdfTool.none;
  Uint8List? _currentDocumentBytes;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadInitialBytes();
  }

  Future<void> _loadInitialBytes() async {
    final bytes = await File(widget.filePath).readAsBytes();
    setState(() {
      _currentDocumentBytes = bytes;
    });
  }

  void _handleSave() async {
    if (_currentDocumentBytes == null) return;
    
    // Use the service to save to disk
    final newPath = await PdfService.saveDocument(_currentDocumentBytes!, widget.filePath, isOverwrite: true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CyberpunkTheme.neonCyan.withOpacity(0.9),
          content: Text("// DOCUMENT_SAVED_AT: $newPath", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  void _onTapHandler(PdfGestureDetails details) {
    if (_activeTool == PdfTool.textOverlay) {
      _showTextInputDialog(details.pageNumber - 1, details.pagePosition);
    }
  }

  Future<void> _showTextInputDialog(int pageIndex, Offset position) async {
    final TextEditingController textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.backgroundDark,
        title: const Text("INJECT TEXT BUFFER", style: TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 14)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter content...",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CyberpunkTheme.neonCyan)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberpunkTheme.neonCyan),
            onPressed: () async {
              final text = textController.text;
              Navigator.pop(context);
              if (text.isNotEmpty) {
                _applyTextOverlay(pageIndex, position, text);
              }
            },
            child: const Text("INJECT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _applyTextOverlay(int pageIndex, Offset position, String text) async {
    if (_currentDocumentBytes == null) return;

    final updatedBytes = await PdfService.addTextToPage(
      bytes: _currentDocumentBytes!,
      pageIndex: pageIndex,
      text: text,
      position: position,
    );

    setState(() {
      _currentDocumentBytes = updatedBytes;
      _activeTool = PdfTool.none; // Reset tool after use
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;

    if (_currentDocumentBytes == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan)));
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          Expanded(
            child: SfPdfViewer.memory(
              _currentDocumentBytes!,
              key: ValueKey(_currentDocumentBytes.hashCode), // Force refresh when bytes change
              controller: _pdfViewerController,
              onTap: _onTapHandler,
              pageLayoutMode: PdfPageLayoutMode.continuous,
            ),
          ),
          if (_showAiPanel && isDesktop) AiAssistantPanel(pdfBytes: _currentDocumentBytes),
        ],
      ),
      endDrawer: !isDesktop ? Drawer(child: AiAssistantPanel(pdfBytes: _currentDocumentBytes)) : null,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildToolButton(
            heroTag: "text_tool",
            icon: Icons.text_fields,
            color: _activeTool == PdfTool.textOverlay ? CyberpunkTheme.neonCyan : Colors.white24,
            onPressed: () => setState(() => _activeTool = _activeTool == PdfTool.textOverlay ? PdfTool.none : PdfTool.textOverlay),
          ),
          const SizedBox(height: 12),
          _buildToolButton(
            heroTag: "save_btn",
            icon: Icons.save,
            color: CyberpunkTheme.neonPink,
            onPressed: _handleSave,
          ),
          const SizedBox(height: 12),
          _buildToolButton(
            heroTag: "ai_btn",
            icon: Icons.auto_awesome,
            color: CyberpunkTheme.neonCyan,
            onPressed: () => setState(() => _showAiPanel = !_showAiPanel),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required String heroTag, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: CyberpunkTheme.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Icon(icon, color: color),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: CyberpunkTheme.backgroundDark,
      title: Text(widget.filePath.split('/').last, style: const TextStyle(fontSize: 14)),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => _pdfViewerKey.currentState?.openBookmarkView()),
        IconButton(icon: const Icon(Icons.edit_note), onPressed: () {}),
        IconButton(icon: const Icon(Icons.share), onPressed: () {}),
      ],
    );
  }
}
