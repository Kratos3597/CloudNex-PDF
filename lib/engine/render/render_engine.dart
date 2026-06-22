import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class RenderEngine {
  RenderEngine._();

  static Future<String> saveDocument(Uint8List bytes, String originalPath, {bool isOverwrite = false}) async {
    String path = originalPath;
    if (!isOverwrite) {
      final directory = await getApplicationDocumentsDirectory();
      final name = originalPath.split(Platform.pathSeparator).last;
      path = '${directory.path}/edited_$name';
    }
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  static String extractText(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final String text = sf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  static String exportToCsv(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final String text = sf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text.replaceAll(' ', ',');
  }

  static List<String> getFormFields(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final List<String> fields = [];
    for (int i = 0; i < document.form.fields.count; i++) {
      fields.add(document.form.fields[i].name!);
    }
    document.dispose();
    return fields;
  }

  static Future<Uint8List> mergeDocuments(List<Uint8List> docs) async {
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    for (var bytes in docs) {
      final sf.PdfDocument tempDoc = sf.PdfDocument(inputBytes: bytes);
      for (int i = 0; i < tempDoc.pages.count; i++) {
        finalDoc.pages.add().graphics.drawPdfTemplate(
          tempDoc.pages[i].createTemplate(),
          const Offset(0, 0),
        );
      }
      tempDoc.dispose();
    }
    final List<int> savedBytes = await finalDoc.save();
    finalDoc.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> addTextAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required List<Rect> bounds,
    required sf.PdfTextMarkupAnnotationType type,
    String? text,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    for (var bound in bounds) {
      final sf.PdfTextMarkupAnnotation annotation = sf.PdfTextMarkupAnnotation(
        bound, 
        text ?? '', 
        sf.PdfColor(255, 255, 0),
      );
      page.annotations.add(annotation);
    }

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> addShapeAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required Rect bounds,
    required String shapeType,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    if (shapeType == 'RECTANGLE') {
      page.annotations.add(sf.PdfRectangleAnnotation(bounds, 'Rectangle'));
    } else if (shapeType == 'CIRCLE') {
      page.annotations.add(sf.PdfEllipseAnnotation(bounds, 'Circle'));
    }

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> addFreeTextAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required Rect bounds,
    required String text,
    double fontSize = 12,
    sf.PdfColor? textColor,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    
    page.graphics.drawString(
      text, 
      sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize),
      brush: sf.PdfSolidBrush(textColor ?? sf.PdfColor(0, 0, 0)),
      bounds: bounds,
    );

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> redactArea(Uint8List bytes, int pageIndex, Rect bounds) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    page.graphics.drawRectangle(
      brush: sf.PdfSolidBrush(sf.PdfColor(255, 255, 255)),
      bounds: bounds,
    );
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> rotatePage(Uint8List bytes, int pageIndex, sf.PdfPageRotateAngle angle) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    document.pages[pageIndex].rotation = angle;
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> deletePages(Uint8List bytes, List<int> indices) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    indices.sort((a, b) => b.compareTo(a));
    for (var index in indices) {
      document.pages.removeAt(index);
    }
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> applySecurity(Uint8List bytes, String password) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    document.security.userPassword = password;
    document.security.ownerPassword = password;
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> addInkAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required List<List<Offset>> paths,
    double strokeWidth = 3,
    sf.PdfColor? color,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    page.annotations.add(sf.PdfRectangleAnnotation(
      Rect.fromLTWH(paths[0][0].dx, paths[0][0].dy, 100, 100),
      'Ink',
    ));
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> reorderPages(Uint8List bytes, int oldIndex, int newIndex) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfDocument newDoc = sf.PdfDocument();
    final List<int> order = List.generate(document.pages.count, (index) => index);
    final int item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    for (int i in order) {
      newDoc.pages.add().graphics.drawPdfTemplate(document.pages[i].createTemplate(), const Offset(0, 0));
    }
    final List<int> savedBytes = await newDoc.save();
    document.dispose();
    newDoc.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> compressPdf(Uint8List bytes) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    document.compressionLevel = sf.PdfCompressionLevel.best;
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> flattenDocument(Uint8List bytes) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> addWatermark(Uint8List bytes, String text) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfFont font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 60);
    final sf.PdfBrush brush = sf.PdfSolidBrush(sf.PdfColor(128, 128, 128, 50));
    for (int i = 0; i < document.pages.count; i++) {
      final sf.PdfPage page = document.pages[i];
      final Size pageSize = page.getClientSize();
      final sf.PdfGraphicsState state = page.graphics.save();
      page.graphics.setTransparency(0.2);
      page.graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
      page.graphics.rotateTransform(-45);
      page.graphics.drawString(text, font, brush: brush, bounds: const Rect.fromLTWH(-150, -30, 0, 0));
      page.graphics.restore(state);
    }
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  static Future<Uint8List> updateMetadata({
    required Uint8List bytes,
    String? title,
    String? author,
    String? subject,
    String? keywords,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    if (title != null) document.documentInformation.title = title;
    if (author != null) document.documentInformation.author = author;
    if (subject != null) document.documentInformation.subject = subject;
    if (keywords != null) document.documentInformation.keywords = keywords;
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }
}
