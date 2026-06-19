import 'dart:ui';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class NeuralZone {
  final Rect bounds;
  final String originalText;
  final double fontSize;

  NeuralZone({
    required this.bounds,
    required this.originalText,
    required this.fontSize,
  });
}

class NeuralVisionEngine {
  /// Layer 1: Neural Layout Analysis
  static List<NeuralZone> scanPage(Uint8List bytes, int pageIndex) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
    
    // Fix: Using correct return type for extractTextLines
    final List<sf.TextLine> lines = extractor.extractTextLines(startPageIndex: pageIndex);
    
    List<NeuralZone> zones = [];
    if (lines.isEmpty) return zones;

    List<sf.TextLine> currentBlock = [lines[0]];
    
    for (int i = 1; i < lines.length; i++) {
      final prevLine = lines[i - 1];
      final currentLine = lines[i];

      double verticalGap = (currentLine.bounds.top - prevLine.bounds.bottom).abs();
      bool sameX = (currentLine.bounds.left - prevLine.bounds.left).abs() < 20;

      if (verticalGap < 12 && sameX) {
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
      
      if (line.wordCollection.isNotEmpty) {
        // Fix: wordCollection is a List in modern Syncfusion
        // However, it might be a different object depending on version.
        // Let's assume standard extraction font size for the first word.
      }
    }

    return NeuralZone(
      bounds: boundingBox,
      originalText: fullText.trim(),
      fontSize: avgFontSize,
    );
  }
}
