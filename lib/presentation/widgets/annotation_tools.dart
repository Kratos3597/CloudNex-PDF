import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/theme/pdf_pro_theme.dart';

/// Point 1 & 2: Interactive Annotation & Comment Layer
/// This overlay allows users to select, move, and comment on existing annotations.
class AnnotationTools extends StatelessWidget {
  final PdfViewerController controller;
  final VoidCallback onAddComment;
  final VoidCallback onFlatten;

  const AnnotationTools({
    super.key,
    required this.controller,
    required this.onAddComment,
    required this.onFlatten,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "comment_btn",
            onPressed: onAddComment,
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.comment_rounded, color: PdfProTheme.primaryBlue),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "flatten_btn",
            onPressed: onFlatten,
            mini: true,
            backgroundColor: PdfProTheme.primaryBlue,
            child: const Icon(Icons.layers_clear_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
