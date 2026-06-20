import 'dart:ui';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:pdfx/pdfx.dart' as px;

class NeuralZone {
  final Rect bounds;
  final String originalText;
  final double fontSize;
  final String label; // Added for classification

  NeuralZone({
    required this.bounds,
    required this.originalText,
    required this.fontSize,
    this.label = 'text',
  });
}

class NeuralVisionEngine {
  /// Renders a PDF page to an image for NPU analysis
  static Future<Uint8List?> renderPageForAi(Uint8List bytes, int pageIndex) async {
    try {
      final document = await px.PdfDocument.openData(bytes);
      final page = await document.getPage(pageIndex + 1); // pdfx is 1-indexed
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: px.PdfPageImageFormat.png,
      );
      await page.close();
      await document.close();
      return pageImage?.bytes;
    } catch (e) {
      return null;
    }
  }

  /// Layer 1: Neural Layout Analysis (Model-First)
  /// In Phase 2, this simulates calling a TFLite model on the NPU.
  static List<NeuralZone> scanPage(Uint8List bytes, int pageIndex) {
    // 1. Heuristic fallback for text extraction (Syncfusion)
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
    final List<sf.TextLine> lines = extractor.extractTextLines(startPageIndex: pageIndex);
    
    List<NeuralZone> zones = [];
    if (lines.isEmpty) {
       document.dispose();
       return zones;
    }

    // Sort lines by position
    lines.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

    List<sf.TextLine> currentBlock = [lines[0]];
    
    for (int i = 1; i < lines.length; i++) {
      final prevLine = lines[i - 1];
      final currentLine = lines[i];

      double verticalGap = (currentLine.bounds.top - prevLine.bounds.bottom).abs();
      bool sameX = (currentLine.bounds.left - prevLine.bounds.left).abs() < 50;

      // Grouping logic (Heuristic until TFLite segmentation is fully wired)
      if (verticalGap < 15 && sameX) {
        currentBlock.add(currentLine);
      } else {
        zones.add(_createNeuralZone(currentBlock));
        currentBlock = [currentLine];
      }
    }
    
    zones.add(_createNeuralZone(currentBlock));
    document.dispose();
    return zones;
  }

  static NeuralZone _createNeuralZone(List<sf.TextLine> lines) {
    Rect boundingBox = lines[0].bounds;
    String fullText = "";
    double avgFontSize = 12.0;
    
    for (var line in lines) {
      boundingBox = boundingBox.expandToInclude(line.bounds);
      fullText += "${line.text} ";
    }

    // Simulated Classification Logic (NPU replacement point)
    String label = 'paragraph';
    if (fullText.length < 50 && boundingBox.height > 20) label = 'heading';
    if (fullText.startsWith('Table') || fullText.contains('|')) label = 'table';

    return NeuralZone(
      bounds: boundingBox,
      originalText: fullText.trim(),
      fontSize: avgFontSize,
      label: label,
    );
  }
}
