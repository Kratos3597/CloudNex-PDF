import 'package:cloudnex_pdf_reader/features/analytics/services/analytics_service.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../../core/theme/cyberpunk_theme.dart';
import '../controller/pdf_state_controller.dart';
import '../services/pdf_modifier_service.dart';
import '../../../services/pdf_service.dart';
import 'signature_pad_view.dart';
import '../../ai_assistant/presentation/ai_panel.dart';

class PdfWorkspaceView extends StatefulWidget {
  final PdfStateController stateController;
  const PdfWorkspaceView({super.key, required this.stateController});

  @override
  State<PdfWorkspaceView> createState() => _PdfWorkspaceViewState();
}

class _PdfWorkspaceViewState extends State<PdfWorkspaceView> {
  bool _showToolMenu = false;
  bool _showSecurityPanel = false;
  bool _showAiPanel = false;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  PdfTextSearchResult? _searchResult;

  // --- ACTIONS ---

  Future<void> _applyAnnotation(sf.PdfTextMarkupAnnotationType type) async {
    final currentSession = widget.stateController.activeSession;
    if (currentSession == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: CyberpunkTheme.backgroundDark,
      content: Text("// SELECT TEXT TO APPLY ${type.name.toUpperCase()}", style: const TextStyle(color: CyberpunkTheme.neonCyan)),
    ));
    
    widget.stateController.toggleTool(
      type == sf.PdfTextMarkupAnnotationType.highlight ? ActivePdfTool.highlight :
      type == sf.PdfTextMarkupAnnotationType.underline ? ActivePdfTool.underline :
      ActivePdfTool.strikeout
    );
  }

  void _handleTextSelection(PdfTextSelectionChangedDetails details) async {
    if (widget.stateController.currentTool == ActivePdfTool.none) return;
    
    final type = widget.stateController.currentTool;
    sf.PdfTextMarkupAnnotationType? sfType;
    if (type == ActivePdfTool.highlight) sfType = sf.PdfTextMarkupAnnotationType.highlight;
    if (type == ActivePdfTool.underline) sfType = sf.PdfTextMarkupAnnotationType.underline;
    if (type == ActivePdfTool.strikeout) sfType = sf.PdfTextMarkupAnnotationType.strikethrough;
    
    if (sfType != null && details.selectedText != null) {
      final currentBytes = widget.stateController.currentBytes;
      if (currentBytes == null) return;
      
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      try {
        final updatedBytes = await PdfService.addTextAnnotation(
          bytes: currentBytes,
          pageIndex: widget.stateController.activePageNumber - 1,
          bounds: [const Rect.fromLTWH(100, 100, 200, 20)], // Placeholder bounds
          type: sfType,
          text: details.selectedText,
        );
        
        if (!mounted) return;
        Navigator.pop(context);
        widget.stateController.commitMutation(updatedBytes);
        widget.stateController.clearActiveTool();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ANNOTATION_ERR: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundDark,
      body: ListenableBuilder(
        listenable: widget.stateController,
        builder: (context, _) {
          if (widget.stateController.sessions.isEmpty) {
            return const Center(child: Text('// NO ACTIVE SESSIONS'));
          }

          final session = widget.stateController.activeSession;
          if (session == null) return const Center(child: CircularProgressIndicator());
          
          final byteStream = session.currentBytes;
          if (byteStream == null) return const Center(child: Text('// DATA_STREAM_LOST'));

          final structuralReport = session.securityReport;

          return Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: SfPdfViewer.memory(
                              byteStream,
                              key: ValueKey("${session.id}_${byteStream.hashCode}"),
                              controller: session.pdfViewerController,
                              initialPageNumber: session.activePageNumber,
                              canShowScrollHead: true,
                              canShowPaginationDialog: true,
                              enableDoubleTapZooming: true,
                              interactionMode: widget.stateController.currentTool == ActivePdfTool.none 
                                  ? PdfInteractionMode.pan : PdfInteractionMode.selection,
                              onTap: _handleCanvasTapIntercept,
                              onPageChanged: (details) => widget.stateController.updatePageNumber(details.newPageNumber),
                              onTextSelectionChanged: _handleTextSelection,
                            ),
                          ),
                          if (_showAiPanel) AiAssistantPanel(pdfBytes: byteStream),
                        ],
                      ),
                    ),
                    // HUD Layer
                    _buildTopBar(structuralReport),
                    if (_isSearching) _buildSearchBar(session),
                    if (_showSecurityPanel && structuralReport != null) _buildSecurityPanel(structuralReport),
                    if (_showToolMenu) _buildToolMenu(),
                    _buildMenuToggle(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      color: Colors.black,
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
                color: isActive ? CyberpunkTheme.backgroundDark : Colors.black,
                border: Border(
                  bottom: BorderSide(color: isActive ? CyberpunkTheme.neonCyan : Colors.transparent, width: 2),
                  right: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    session.fileName.toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white38,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, color: isActive ? Colors.white54 : Colors.white24),
                    onPressed: () => widget.stateController.closeSession(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(PdfSession session) {
    return Positioned(
      top: 110, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: CyberpunkTheme.glassDecoration(),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(hintText: "SEARCH_BUFFER...", border: InputBorder.none),
                onSubmitted: (val) {
                  setState(() {
                    _searchResult = session.pdfViewerController.searchText(val);
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: CyberpunkTheme.neonPink),
              onPressed: () {
                _searchResult?.clear();
                setState(() => _isSearching = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PdfSecurityReport? report) => Positioned(
        top: 20, left: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: CyberpunkTheme.glassDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => widget.stateController.pdfViewerController?.zoomLevel += 0.25),
                  IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => widget.stateController.pdfViewerController?.zoomLevel -= 0.25),
                  IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = !_isSearching)),
                ],
              ),
              Text('PAGE: ${widget.stateController.activePageNumber}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              IconButton(icon: const Icon(Icons.shield), onPressed: () => setState(() => _showSecurityPanel = !_showSecurityPanel)),
            ],
          ),
        ),
      );

  Widget _buildToolMenu() => Positioned(
        right: 16,
        bottom: 110,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildToolButton(
                icon: Icons.border_color,
                onPressed: () => _applyAnnotation(sf.PdfTextMarkupAnnotationType.highlight),
                isActive: widget.stateController.currentTool == ActivePdfTool.highlight,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.format_underlined,
                onPressed: () => _applyAnnotation(sf.PdfTextMarkupAnnotationType.underline),
                isActive: widget.stateController.currentTool == ActivePdfTool.underline,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.strikethrough_s,
                onPressed: () => _applyAnnotation(sf.PdfTextMarkupAnnotationType.strikethrough),
                isActive: widget.stateController.currentTool == ActivePdfTool.strikeout,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.gesture,
                onPressed: _openSignaturePad,
                isActive: widget.stateController.currentTool == ActivePdfTool.signaturePlacement,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.document_scanner,
                onPressed: _handleOcr,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.assignment_turned_in_outlined,
                onPressed: _handleFormFilling,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.analytics_outlined,
                onPressed: _handleReportGeneration,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.save,
                onPressed: _executeSystemSave,
              ),
              const SizedBox(height: 12),
              _buildToolButton(
                icon: Icons.auto_awesome,
                onPressed: () => setState(() => _showAiPanel = !_showAiPanel),
                isActive: _showAiPanel,
              ),
            ],
          ),
        ),
      );
      
  Future<void> _handleOcr() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan)),
    );

    try {
      final ocrResult = await PdfService.performOCR(currentBytes);
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: CyberpunkTheme.backgroundDark,
          title: Text("OCR_EXTRACTION_SUCCESS //", style: CyberpunkTheme.neonTextStyle(fontSize: 14)),
          content: SingleChildScrollView(
            child: Text(ocrResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CLOSE", style: CyberpunkTheme.neonTextStyle(color: CyberpunkTheme.neonPink)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OCR_FAILED: $e")));
    }
  }

  Future<void> _handleFormFilling() async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final fields = PdfService.getFormFields(currentBytes);
    if (fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: CyberpunkTheme.backgroundDark,
        content: Text("// NO_FORM_FIELDS_DETECTED", style: TextStyle(color: CyberpunkTheme.neonPink)),
      ));
      return;
    }

    final Map<String, dynamic> updatedData = Map.from(fields);
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.backgroundDark,
        title: Text("FORM_INJECTOR //", style: CyberpunkTheme.neonTextStyle(fontSize: 14)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: updatedData.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: TextEditingController(text: updatedData[key].toString()),
                    onChanged: (val) => updatedData[key] = val,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: key.toUpperCase(),
                      labelStyle: const TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 10),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: CyberpunkTheme.neonCyan)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberpunkTheme.neonCyan.withValues(alpha: 0.2)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("COMMIT", style: TextStyle(color: CyberpunkTheme.neonCyan)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBytes = await PdfService.fillFormFields(currentBytes, updatedData);
      if (!mounted) return;
      Navigator.pop(context);
      widget.stateController.commitMutation(updatedBytes);
    }
  }

  Future<void> _handleReportGeneration() async {
    final session = widget.stateController.activeSession;
    if (session == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final String summaryContent = "This is an automated intelligence report for ${session.fileName}.\n\n"
          "The document contains ${session.securityReport?.totalPages ?? 0} pages.\n"
          "Security Status: ${session.securityReport?.complianceStatus ?? 'UNKNOWN'}.\n"
          "Author: ${session.securityReport?.authorSignature ?? 'UNVERIFIED'}.\n\n"
          "Analysis completed at ${DateTime.now()}.";

      final reportBytes = await PdfService.generateReport(
        title: "NEURAL_ANALYSIS_REPORT",
        content: summaryContent,
        tableData: [
          {"FILE_ID": session.id},
          {"ENCRYPTION": session.securityReport?.isEncrypted.toString() ?? 'FALSE'},
        ],
      );

      if (!mounted) return;
      Navigator.pop(context);

      widget.stateController.openDocument(reportBytes, "report_${DateTime.now().millisecondsSinceEpoch}.pdf");
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: CyberpunkTheme.backgroundDark,
        content: Text("// REPORT_GENERATED_AND_OPENED", style: TextStyle(color: CyberpunkTheme.neonGreen)),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("GEN_ERR: $e")));
    }
  }

  Future<void> _executeSystemSave() async {
    final currentBytes = widget.stateController.currentBytes;
    final session = widget.stateController.activeSession;
    if (currentBytes == null || session == null) return;
    
    final bool success = await PdfModifierService.saveDocumentViaSystemPicker(
      bytes: currentBytes,
      suggestedName: 'cloudnex_export.pdf',
    );
    if (!mounted) return;
    
    if (success) {
      analyticsService.logAction("EXPORT_DOCUMENT", session.fileName);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: CyberpunkTheme.backgroundDark,
      content: Text(success ? '// EXPORT COMPLETED' : '// EXPORT ABORTED',
          style: TextStyle(color: success ? CyberpunkTheme.neonGreen : CyberpunkTheme.neonPink)),
    ));
  }

  Future<void> _openSignaturePad() async {
    final Uint8List? signature = await showDialog<Uint8List>(
      context: context,
      builder: (context) => const SignaturePadView(),
    );

    if (signature != null) {
      if (!mounted) return;
      widget.stateController.setupSignaturePlacement(signature);
    }
  }

  Future<void> _applyGraphicSignature({required int pageIndex, required double x, required double y}) async {
    final currentRawBytes = widget.stateController.currentBytes;
    final graphicBytes = widget.stateController.activeSignatureGraphicBytes;
    if (currentRawBytes == null || graphicBytes == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final updatedBytes = await PdfModifierService.injectGraphicSignatureAsync(
      originalBytes: currentRawBytes,
      targetPageZeroIndexed: pageIndex,
      signatureImageBytes: graphicBytes,
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
    if (widget.stateController.currentTool == ActivePdfTool.signaturePlacement) {
      _applyGraphicSignature(pageIndex: details.pageNumber - 1, x: details.pagePosition.dx, y: details.pagePosition.dy);
    }
  }

  Widget _buildMenuToggle() => Positioned(
        right: 16, bottom: 30,
        child: FloatingActionButton(
          backgroundColor: CyberpunkTheme.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CyberpunkTheme.neonCyan)),
          onPressed: () => setState(() => _showToolMenu = !_showToolMenu),
          child: Icon(_showToolMenu ? Icons.close : Icons.apps, color: CyberpunkTheme.neonCyan),
        ),
      );

  Widget _buildSecurityPanel(PdfSecurityReport report) => Positioned(
        top: 120, left: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: CyberpunkTheme.glassDecoration(),
          child: Column(children: [
            Text('STATUS: ${report.complianceStatus}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('ENCRYPTED: ${report.isEncrypted}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      );

  Widget _buildToolButton({required IconData icon, required VoidCallback onPressed, bool isActive = false}) {
    return Container(
      decoration: CyberpunkTheme.glassDecoration(
        borderRadius: BorderRadius.circular(12),
        borderColor: isActive ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonCyan.withValues(alpha: 0.3),
      ),
      child: IconButton(icon: Icon(icon, color: isActive ? CyberpunkTheme.neonCyan : Colors.white), onPressed: onPressed),
    );
  }
}
