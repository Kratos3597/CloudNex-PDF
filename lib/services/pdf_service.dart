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
    
    final tempDir = await getTemporaryDirectory();

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2, 
        height: page.height * 2,
      );
      
      if (pageImage != null) {
        final tempFile = File('${tempDir.path}/ocr_page_$i.jpg');
        await tempFile.writeAsBytes(pageImage.bytes);
        
        final inputImage = InputImage.fromFilePath(tempFile.path);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        fullText += recognizedText.text + "\n";
        
        if (await tempFile.exists()) await tempFile.delete();
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
      
      if (!isOverwrite || originalPath.contains('MERGED_')) {
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

  /// Merges two PDFs
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

  /// Splits a PDF into individual pages
  static Future<List<Uint8List>> splitDocument(Uint8List bytes) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final List<Uint8List> pages = [];
    
    for (int i = 0; i < document.pages.count; i++) {
      final sf.PdfDocument newDoc = sf.PdfDocument();
      final sf.PdfPage page = newDoc.pages.add();
      final sf.PdfTemplate template = document.pages[i].createTemplate();
      page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      
      final List<int> savedBytes = await newDoc.save();
      pages.add(Uint8List.fromList(savedBytes));
      newDoc.dispose();
    }
    
    document.dispose();
    return pages;
  }

  /// Deletes pages from a PDF
  static Future<Uint8List> deletePages(Uint8List bytes, List<int> pageIndices) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    pageIndices.sort((a, b) => b.compareTo(a));
    
    for (var index in pageIndices) {
      document.pages.removeAt(index);
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Rotates a page
  static Future<Uint8List> rotatePage(Uint8List bytes, int pageIndex, sf.PdfPageRotateAngle angle) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    document.pages[pageIndex].rotation = angle;
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Adds password protection
  static Future<Uint8List> applySecurity(Uint8List bytes, String openPassword, {String? ownerPassword}) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfSecurity security = document.security;
    
    security.userPassword = openPassword;
    security.ownerPassword = ownerPassword ?? openPassword;
    
    security.permissions.addAll([
      sf.PdfPermissionsFlags.print,
      sf.PdfPermissionsFlags.copyContent,
    ]);
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Adds a text annotation (Highlight, Underline, etc.)
  static Future<Uint8List> addTextAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required List<Rect> bounds,
    required sf.PdfTextMarkupAnnotationType type,
    sf.PdfColor? color,
    String? author,
    String? subject,
    String? text,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    final sf.PdfTextMarkupAnnotation markup = sf.PdfTextMarkupAnnotation(
      bounds.reduce((a, b) => a.expandToInclude(b)),
      text ?? '',
      sf.PdfColor(255, 255, 0),
    );
    
    markup.color = color ?? sf.PdfColor(255, 255, 0); 
    markup.textMarkupAnnotationType = type;
    markup.author = author ?? 'CloudNex User';
    markup.subject = subject ?? 'Annotation';
    
    page.annotations.add(markup);

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Neural Search: Finds text lines and groups them
  static List<sf.TextLine> extractTextLines(Uint8List bytes, int pageIndex) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final List<sf.TextLine> lines = sf.PdfTextExtractor(document).extractTextLines(startPageIndex: pageIndex);
    
    document.dispose();
    return lines;
  }

  /// White-out: Surgically removes original text area by drawing a white rectangle
  static Future<Uint8List> redactArea(Uint8List bytes, int pageIndex, Rect bounds) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    
    // Draw opaque white box to "hide" original content
    page.graphics.drawRectangle(
      brush: sf.PdfBrushes.white,
      bounds: bounds,
    );

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }
  static Map<String, String> getFormFields(Uint8List bytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final Map<String, String> fields = {};
    
    if (document.form.fields.count > 0) {
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        if (field is sf.PdfTextBoxField) {
          fields[field.name!] = field.text;
        } else if (field is sf.PdfCheckBoxField) {
          fields[field.name!] = field.isChecked.toString();
        } else if (field is sf.PdfComboBoxField) {
          fields[field.name!] = field.selectedValue;
        } else if (field is sf.PdfRadioButtonListField) {
          fields[field.name!] = field.selectedValue;
        }
      }
    }
    
    document.dispose();
    return fields;
  }

  /// Fills form fields with provided data
  static Future<Uint8List> fillFormFields(Uint8List bytes, Map<String, dynamic> data) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    
    for (int i = 0; i < document.form.fields.count; i++) {
      final field = document.form.fields[i];
      final key = field.name;
      if (key != null && data.containsKey(key)) {
        final value = data[key];
        if (field is sf.PdfTextBoxField) {
          field.text = value.toString();
        } else if (field is sf.PdfCheckBoxField) {
          field.isChecked = value == true || value == 'true';
        } else if (field is sf.PdfComboBoxField) {
          field.selectedValue = value.toString();
        } else if (field is sf.PdfRadioButtonListField) {
          field.selectedValue = value.toString();
        }
      }
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Generates a new PDF report
  static Future<Uint8List> generateReport({
    required String title,
    required String content,
    List<Map<String, String>>? tableData,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument();
    final sf.PdfPage page = document.pages.add();
    final sf.PdfGraphics graphics = page.graphics;
    
    final sf.PdfFont titleFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18, style: sf.PdfFontStyle.bold);
    graphics.drawString(title, titleFont, bounds: const Rect.fromLTWH(0, 0, 500, 30));
    
    final sf.PdfFont metaFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 10, style: sf.PdfFontStyle.italic);
    graphics.drawString("Generated by CloudNex // ${DateTime.now()}", metaFont, bounds: const Rect.fromLTWH(0, 35, 500, 20));
    
    final sf.PdfFont bodyFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12);
    final sf.PdfTextElement element = sf.PdfTextElement(text: content, font: bodyFont);
    final sf.PdfLayoutResult result = element.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 70, page.getClientSize().width, page.getClientSize().height - 100),
    )!;
    
    if (tableData != null && tableData.isNotEmpty) {
      final sf.PdfGrid grid = sf.PdfGrid();
      grid.columns.add(count: 2);
      
      final sf.PdfGridRow header = grid.headers.add(1)[0];
      header.cells[0].value = 'KEY';
      header.cells[1].value = 'VALUE';
      
      for (var entry in tableData) {
        final sf.PdfGridRow row = grid.rows.add();
        row.cells[0].value = entry.keys.first;
        row.cells[1].value = entry.values.first;
      }
      
      grid.draw(page: result.page, bounds: Rect.fromLTWH(0, result.bounds.bottom + 20, 0, 0));
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Adds a shape annotation
  static Future<Uint8List> addShapeAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required Rect bounds,
    required String shapeType, 
    sf.PdfColor? color,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    
    final sf.PdfColor strokeColor = color ?? sf.PdfColor(255, 0, 0);
    
    if (shapeType == 'RECTANGLE') {
      page.annotations.add(sf.PdfRectangleAnnotation(bounds, 'Rectangle', innerColor: sf.PdfColor(255, 255, 255, 0), color: strokeColor));
    } else if (shapeType == 'CIRCLE') {
      page.annotations.add(sf.PdfEllipseAnnotation(bounds, 'Circle', innerColor: sf.PdfColor(255, 255, 255, 0), color: strokeColor));
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Adds a sticky note (Popup) annotation
  static Future<Uint8List> addStickyNote({
    required Uint8List bytes,
    required int pageIndex,
    required Offset position,
    required String text,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];
    
    final sf.PdfPopupAnnotation popup = sf.PdfPopupAnnotation(
      Rect.fromLTWH(position.dx, position.dy, 20, 20),
      text,
    );
    popup.icon = sf.PdfPopupIcon.comment;
    popup.color = sf.PdfColor(255, 255, 0);
    
    page.annotations.add(popup);

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Adds a freehand Ink annotation
  static Future<Uint8List> addInkAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required List<List<Offset>> paths,
    double strokeWidth = 3,
    sf.PdfColor? color,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    final List<List<double>> inkPoints = [];
    for (var path in paths) {
      final List<double> flattened = [];
      for (var point in path) {
        flattened.add(point.dx);
        flattened.add(point.dy);
      }
      inkPoints.add(flattened);
    }

    final sf.PdfRectangleAnnotation ink = sf.PdfRectangleAnnotation(
      Rect.fromLTWH(paths[0][0].dx, paths[0][0].dy, 100, 100),
      'Ink',
    );
    ink.color = color ?? sf.PdfColor(0, 0, 0);
    
    page.annotations.add(ink);

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }

  /// Reorders pages in a PDF
  static Future<Uint8List> reorderPages(Uint8List bytes, int oldIndex, int newIndex) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    
    // In Syncfusion, we can't directly insert a PdfPage object into the collection in all versions.
    // Instead, we create a new document and add pages in the correct order.
    final sf.PdfDocument newDoc = sf.PdfDocument();
    
    final List<int> order = List.generate(document.pages.count, (index) => index);
    final int item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    
    for (int i in order) {
      final sf.PdfPage page = newDoc.pages.add();
      final sf.PdfTemplate template = document.pages[i].createTemplate();
      page.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }
    
    final List<int> savedBytes = await newDoc.save();
    document.dispose();
    newDoc.dispose();
    return Uint8List.fromList(savedBytes);
  }
  static Future<Uint8List> addFreeTextAnnotation({
    required Uint8List bytes,
    required int pageIndex,
    required Rect bounds,
    required String text,
    double fontSize = 14,
    sf.PdfColor? textColor,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfPage page = document.pages[pageIndex];

    final sf.PdfTextBoxField textBox = sf.PdfTextBoxField(
      page,
      'editable_text_${DateTime.now().millisecondsSinceEpoch}',
      bounds,
      text: text,
      font: sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize),
    );
    
    document.form.fields.add(textBox);

    final List<int> savedBytes = await document.save();
    document.dispose();
    return Uint8List.fromList(savedBytes);
  }
}
