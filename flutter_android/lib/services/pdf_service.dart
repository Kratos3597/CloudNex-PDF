import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CloudNexPdfService {
  /// Applies a digital signature image stamp to a specific page and flattens it
  /// into the underlying vector PDF content stream.
  static Future<File> applySignatureAndFlatten({
    required List<int> originalPdfBytes,
    required Uint8Array signaturePngBytes,
    required int pageIndex,
    required Rect boundingBox,
    required String outputFileName,
  }) async {
    // 1. Load document using Syncfusion Flutter PDF engine
    final PdfDocument document = PdfDocument(inputBytes: originalPdfBytes);

    try {
      // 2. Access the target page
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw ArgumentError('Invalid page index: $pageIndex');
      }
      final PdfPage page = document.pages[pageIndex];

      // 3. Create high-resolution signature bitmap
      final PdfBitmap signatureBitmap = PdfBitmap(signaturePngBytes);

      // 4. Draw signature onto page graphics layer
      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          boundingBox.left,
          boundingBox.top,
          boundingBox.width,
          boundingBox.height,
        ),
      );

      // 5. Flatten all existing form fields & annotations
      if (document.form.fields.count > 0) {
        document.form.flattenAllFields();
      }

      // 6. Compress and save to application temporary cache
      final List<int> outputBytes = await document.save();
      final Directory tempDir = await getTemporaryDirectory();
      final File savedFile = File('${tempDir.path}/$outputFileName');
      await savedFile.writeAsBytes(outputBytes, flush: true);

      return savedFile;
    } finally {
      // Always dispose document to free native memory
      document.dispose();
    }
  }

  /// Generates a test high-density image-heavy PDF for stress testing
  static Future<File> createStressTestImagePdf() async {
    final PdfDocument document = PdfDocument();
    
    try {
      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfBrush blueBrush = PdfSolidBrush(PdfColor(0, 82, 204));
      final PdfBrush textBrush = PdfSolidBrush(PdfColor(23, 43, 77));

      // Create 5 rich pages with simulated blueprint/scanned drawings
      for (int i = 1; i <= 5; i++) {
        final PdfPage page = document.pages.add();
        final Size pageSize = page.getClientSize();

        // Header
        page.graphics.drawString(
          'CLOUDNEX HIGH-RESOLUTION SCAN #$i',
          headerFont,
          brush: blueBrush,
          bounds: Rect.fromLTWH(0, 0, pageSize.width, 30),
        );

        page.graphics.drawString(
          'DPI Stress Simulation: 300 DPI Architectural Matrix & Encryption Log',
          bodyFont,
          brush: textBrush,
          bounds: Rect.fromLTWH(0, 32, pageSize.width, 20),
        );

        // Draw intricate vector grid to simulate CAD/Blueprint density
        final PdfPen gridPen = PdfPen(PdfColor(220, 225, 235), width: 0.5);
        for (double x = 0; x < pageSize.width; x += 15) {
          page.graphics.drawLine(gridPen, Offset(x, 60), Offset(x, pageSize.height - 40));
        }
        for (double y = 60; y < pageSize.height - 40; y += 15) {
          page.graphics.drawLine(gridPen, Offset(0, y), Offset(pageSize.width, y));
        }

        // Add certified stamp box
        final PdfPen stampPen = PdfPen(PdfColor(54, 179, 126), width: 2);
        page.graphics.drawRectangle(
          pen: stampPen,
          bounds: Rect.fromLTWH(pageSize.width - 210, pageSize.height - 110, 200, 90),
        );
        page.graphics.drawString(
          'VERIFIED AUDIT LOG\nPage $i of 5\nSyncfusion Hardware Engine\nStatus: Tamper-Evident',
          bodyFont,
          brush: PdfSolidBrush(PdfColor(54, 179, 126)),
          bounds: Rect.fromLTWH(pageSize.width - 200, pageSize.height - 100, 180, 70),
        );
      }

      final List<int> bytes = await document.save();
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/CloudNex_Large_Sample.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      document.dispose();
    }
  }

  /// Shares a PDF file using the native Android share sheet with FileProvider
  static Future<ShareResult> sharePdfFile({
    required File pdfFile,
    required String subject,
    String? text,
  }) async {
    final XFile xFile = XFile(
      pdfFile.path,
      mimeType: 'application/pdf',
      name: pdfFile.path.split('/').last,
    );

    return await Share.shareXFiles(
      [xFile],
      subject: subject,
      text: text ?? 'Here is the signed PDF document from CloudNex PDF Pro.',
    );
  }
}
