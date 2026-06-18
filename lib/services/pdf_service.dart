import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  /// Injects text into a specific page at given coordinates
  static Future<Uint8List> addTextToPage({
    required Uint8List bytes,
    required int pageIndex,
    required String text,
    required Offset position,
    double fontSize = 12,
  }) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfPage page = document.pages[pageIndex];

    // Standard PDF coordinates start from bottom-left, but Syncfusion UI 
    // and PDF engine use top-left for drawing. 
    page.graphics.drawString(
      text,
      PdfStandardFont(PdfFontFamily.helvetica, fontSize),
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(position.dx, position.dy, 0, 0),
    );

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Saves the modified PDF bytes to the original path or a new path
  static Future<String> saveDocument(Uint8List bytes, String originalPath, {bool isOverwrite = false}) async {
    try {
      String savePath = originalPath;
      
      if (!isOverwrite) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = originalPath.split('/').last;
        savePath = "${directory.path}/EDITED_${DateTime.now().millisecondsSinceEpoch}_$fileName";
      }

      final file = File(savePath);
      await file.writeAsBytes(bytes);
      return savePath;
    } catch (e) {
      throw Exception("Failed to save document: $e");
    }
  }

  /// Example: Merging two PDFs
  static Future<Uint8List> mergeDocuments(List<Uint8List> documents) async {
    final PdfDocument finalDoc = PdfDocument();
    for (var docBytes in documents) {
      final PdfDocument inputDoc = PdfDocument(inputBytes: docBytes);
      finalDoc.importPages(inputDoc, 0, inputDoc.pages.count - 1, finalDoc.pages.count);
    }
    final List<int> bytes = await finalDoc.save();
    finalDoc.dispose();
    return Uint8List.fromList(bytes);
  }
}
