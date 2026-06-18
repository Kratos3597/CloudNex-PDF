import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart' as px;

class PdfService {
  /// Extracts all text from a PDF for RAG/AI context
  static String extractText(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    String text = sf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  /// OCR: Extract text from images within the PDF
  static Future<String> performOCR(Uint8List bytes) async {
    final px.PdfDocument document = await px.PdfDocument.openData(bytes);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String fullText = "";

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(width: page.width * 2, height: page.height * 2);
      
      if (pageImage != null) {
        final inputImage = InputImage.fromBytes(
          bytes: pageImage.bytes,
          metadata: InputImageMetadata(
            size: Size(pageImage.width!.toDouble(), pageImage.height!.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: pageImage.width! * 4,
          ),
        );
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        fullText += recognizedText.text + "\n";
      }
      await page.close();
    }
    
    await document.close();
    await textRecognizer.close();
    return fullText;
  }

  /// Export PDF content to a simple CSV-like string (simulating Excel)
  static String exportToCsv(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final List<sf.TextLine> lines = sf.PdfTextExtractor(document).extractTextLines();
    
    String csv = "";
    for (var line in lines) {
      // Very primitive heuristic: split by multiple spaces
      final parts = line.text.split(RegExp(r'\s{2,}'));
      csv += parts.map((e) => '"${e.replaceAll('"', '""')}"').join(',') + "\n";
    }
    
    document.dispose();
    return csv;
  }

  /// Injects text into a specific page at given coordinates
  static Future<Uint8List> addTextToPage({
    required Uint8List bytes,
    required int pageIndex,
    required String text,
    required Offset position,
    double fontSize = 12,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    page.graphics.drawString(
      text,
      sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize),
      brush: sf.PdfBrushes.black,
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
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    for (var docBytes in documents) {
      final sf.PdfDocument inputDoc = sf.PdfDocument(inputBytes: docBytes);
      for (int i = 0; i < inputDoc.pages.count; i++) {
        final sf.PdfPage page = finalDoc.pages.add();
        final sf.PdfTemplate template = inputDoc.pages[i].createTemplate();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      inputDoc.dispose();
    }
    final List<int> bytes = await finalDoc.save();
    finalDoc.dispose();
    return Uint8List.fromList(bytes);
  }
}
