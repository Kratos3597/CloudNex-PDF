import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class TextLineGroup {
  final List<sf.TextLine> lines;
  final Rect boundingBox;
  final String text;

  TextLineGroup({
    required this.lines,
    required this.boundingBox,
    required this.text,
  });
}

class LayoutAnalyzer {
  /// Heuristic Text Grouping: Groups floating lines into logical "Paragraph Boxes"
  static List<TextLineGroup> identifyParagraphs(List<sf.TextLine> allLines) {
    if (allLines.isEmpty) return [];

    // Sort lines primarily by vertical position (Top to Bottom)
    allLines.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

    List<TextLineGroup> paragraphs = [];
    List<sf.TextLine> currentGroup = [allLines.first];

    for (int i = 1; i < allLines.length; i++) {
      final prevLine = allLines[i - 1];
      final currentLine = allLines[i];

      // Heuristic: If vertical distance is small and horizontal alignment is similar, they belong together
      double verticalDist = (currentLine.bounds.top - prevLine.bounds.bottom).abs();
      double horizontalOverlap = _calculateHorizontalOverlap(prevLine.bounds, currentLine.bounds);

      if (verticalDist < 15 && horizontalOverlap > 0.5) {
        currentGroup.add(currentLine);
      } else {
        paragraphs.add(_createGroup(currentGroup));
        currentGroup = [currentLine];
      }
    }
    
    paragraphs.add(_createGroup(currentGroup));
    return paragraphs;
  }

  static double _calculateHorizontalOverlap(Rect a, Rect b) {
    double start = a.left > b.left ? a.left : b.left;
    double end = a.right < b.right ? a.right : b.right;
    if (start >= end) return 0;
    double overlap = end - start;
    return overlap / (a.width > b.width ? a.width : b.width);
  }

  static TextLineGroup _createGroup(List<sf.TextLine> lines) {
    Rect box = lines.first.bounds;
    String fullText = "";
    for (var line in lines) {
      box = box.expandToInclude(line.bounds);
      fullText += "${line.text} ";
    }
    return TextLineGroup(lines: lines, boundingBox: box, text: fullText.trim());
  }
}
