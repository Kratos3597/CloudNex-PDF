import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result from OCR processing of a single recognized word
class FlutterOcrWord {
  final String text;
  final Rect boundingBox;
  final double confidence;

  FlutterOcrWord({
    required this.text,
    required this.boundingBox,
    this.confidence = 1.0,
  });
}

/// Result of OCR extraction across an entire document
class FlutterOcrResult {
  final String fullText;
  final int totalWords;
  final List<List<FlutterOcrWord>> pagesWords;
  final File? searchablePdfFile;

  FlutterOcrResult({
    required this.fullText,
    required this.totalWords,
    required this.pagesWords,
    this.searchablePdfFile,
  });
}

/// Service providing on-device Google ML Kit OCR coupled with Syncfusion PDF Document writer
class FlutterOcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analyzes an image file (e.g. captured camera page or rasterized PDF page)
  /// using Google ML Kit Text Recognition and returns structured words with bounding boxes.
  static Future<List<FlutterOcrWord>> recognizeImageFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final List<FlutterOcrWord> words = [];
    for (final textBlock in recognizedText.blocks) {
      for (final line in textBlock.lines) {
        for (final element in line.elements) {
          words.add(
            FlutterOcrWord(
              text: element.text,
              boundingBox: element.boundingBox,
              confidence: element.confidence ?? 1.0,
            ),
          );
        }
      }
    }
    return words;
  }

  /// Converts a scanned image into a searchable, selectable PDF using Syncfusion's PdfDocument
  /// with invisible text overlaid directly on top of the original image bytes.
  static Future<File> createSearchablePdfFromImage({
    required File imageFile,
    required String outputFileName,
  }) async {
    // 1. Run Google ML Kit Text Recognition on the scanned image
    final List<FlutterOcrWord> detectedWords = await recognizeImageFile(imageFile);

    // 2. Instantiate Syncfusion PDF Document
    final PdfDocument document = PdfDocument();

    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final PdfBitmap bitmap = PdfBitmap(imageBytes);

      // Create a page matching the image dimensions
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // 3. Draw the background scan bitmap into the Syncfusion graphics layer
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      // 4. Overlay recognized OCR words using an invisible brush
      // Setting text rendering mode to invisible allows users to select, copy,
      // and search (Ctrl+F) the text while visually seeing the crisp original scan!
      final PdfFont ocrFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfBrush invisibleBrush = PdfSolidBrush(const PdfColor(0, 0, 0, 0)); // Transparent alpha

      for (final word in detectedWords) {
        if (word.text.trim().isEmpty) continue;

        // Scale bounding box coordinates from image coordinates to PDF points if needed
        final double scaleX = pageSize.width / (bitmap.width > 0 ? bitmap.width : pageSize.width);
        final double scaleY = pageSize.height / (bitmap.height > 0 ? bitmap.height : pageSize.height);

        final Rect scaledRect = Rect.fromLTWH(
          word.boundingBox.left * scaleX,
          word.boundingBox.top * scaleY,
          word.boundingBox.width * scaleX,
          word.boundingBox.height * scaleY,
        );

        page.graphics.drawString(
          word.text,
          ocrFont,
          brush: invisibleBrush,
          bounds: scaledRect,
        );
      }

      // 5. Compress and save the resulting searchable PDF
      final List<int> outputBytes = await document.save();
      final Directory tempDir = await getTemporaryDirectory();
      final File savedFile = File('${tempDir.path}/$outputFileName');
      await savedFile.writeAsBytes(outputBytes, flush: true);

      return savedFile;
    } finally {
      document.dispose();
    }
  }

  /// Injects an invisible OCR searchable text stream into an existing PDF page
  /// using Syncfusion's PdfDocument graphics layer.
  static Future<File> injectOcrTextLayer({
    required List<int> originalPdfBytes,
    required int pageIndex,
    required List<FlutterOcrWord> ocrWords,
    required String outputFileName,
  }) async {
    final PdfDocument document = PdfDocument(inputBytes: originalPdfBytes);

    try {
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw ArgumentError('Invalid page index: $pageIndex');
      }

      final PdfPage page = document.pages[pageIndex];
      final PdfFont ocrFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfBrush invisibleBrush = PdfSolidBrush(const PdfColor(0, 0, 0, 0));

      for (final word in ocrWords) {
        if (word.text.trim().isEmpty) continue;
        page.graphics.drawString(
          word.text,
          ocrFont,
          brush: invisibleBrush,
          bounds: word.boundingBox,
        );
      }

      final List<int> outputBytes = await document.save();
      final Directory tempDir = await getTemporaryDirectory();
      final File savedFile = File('${tempDir.path}/$outputFileName');
      await savedFile.writeAsBytes(outputBytes, flush: true);

      return savedFile;
    } finally {
      document.dispose();
    }
  }

  /// Clean up native recognizer resources when app closes
  static void dispose() {
    _textRecognizer.close();
  }
}
