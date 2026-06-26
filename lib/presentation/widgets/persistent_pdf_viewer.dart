import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/state/app_state.dart';

class PersistentPdfViewer extends StatefulWidget {
  final Uint8List bytes;
  final PdfViewerController controller;
  final int initialPage;
  final bool isEditMode;
  final Function(PdfGestureDetails) onTap;
  final Function(PdfPageChangedDetails) onPageChanged;
  final Function(PdfTextSelectionChangedDetails) onTextSelectionChanged;

  const PersistentPdfViewer({
    super.key,
    required this.bytes,
    required this.controller,
    required this.initialPage,
    required this.isEditMode,
    required this.onTap,
    required this.onPageChanged,
    required this.onTextSelectionChanged,
  });

  @override
  State<PersistentPdfViewer> createState() => _PersistentPdfViewerState();
}

class _PersistentPdfViewerState extends State<PersistentPdfViewer> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // REPAINT BOUNDARY: GPU-level isolation for the renderer
    return RepaintBoundary(
      child: SfPdfViewer.memory(
        widget.bytes,
        controller: widget.controller,
        initialPageNumber: widget.initialPage,
        pageLayoutMode: PdfPageLayoutMode.continuous,
        scrollDirection: PdfScrollDirection.vertical,
        enableTextSelection: widget.isEditMode,
        enableDocumentLinkAnnotation: true,
        // LOCK INTERACTION: Prevents resets during mode toggles
        interactionMode: widget.isEditMode 
            ? PdfInteractionMode.selection 
            : PdfInteractionMode.pan,
        onTap: widget.onTap,
        onPageChanged: widget.onPageChanged,
        onTextSelectionChanged: widget.onTextSelectionChanged,
      ),
    );
  }
}
