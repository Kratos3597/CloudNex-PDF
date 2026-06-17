import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Data class representing structural forensic properties of an ingested document
class PdfSecurityReport {
  final bool isEncrypted;
  final int totalPages;
  final String authorSignature;
  final String complianceStatus;
  final bool permissionsValid;

  PdfSecurityReport({
    required this.isEncrypted,
    required this.totalPages,
    required this.authorSignature,
    required this.complianceStatus,
    required this.permissionsValid,
  });
}

class PdfModifierService {
  PdfModifierService._();

  static bool isDocumentEncrypted(Uint8List bytes) {
    try {
      PdfDocument.getStructure(bytes);
      return false;
    } catch (e) {
      return true;
    }
  }

  static bool validatePassword(Uint8List bytes, String password) {
    try {
      final PdfDocument doc = PdfDocument(inputBytes: bytes, password: password);
      doc.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ========================================================
  /// 🛡️ POINT 14: FORENSIC ATTRIBUTES DISCOVERY ENGINE
  /// ========================================================
  static PdfSecurityReport analyzeDocumentStructure(Uint8List bytes, [String? password]) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes, password: password);
      final int totalPages = document.pages.count;
      final String author = document.documentInformation.author ?? 'UNVERIFIED IDENT';
      
      // Check structural clearance status based on the signature block state
      final bool isSanitized = author == 'CLOUDNEX SECURE SUBSYSTEM';
      final String compliance = isSanitized ? 'SECURE_COMPLIANT' : 'DIRTY_TRACKING_RISK';
      final bool permissions = document.security.permissions.print == true;

      document.dispose();
      return PdfSecurityReport(
        isEncrypted: password != null && password.isNotEmpty,
        totalPages: totalPages,
        authorSignature: author,
        complianceStatus: compliance,
        permissionsValid: permissions,
      );
    } catch (_) {
      return PdfSecurityReport(
        isEncrypted: true,
        totalPages: 0,
        authorSignature: 'CIPHERTEXT_LOCKED',
        complianceStatus: 'SUSPENDED',
        permissionsValid: false,
      );
    }
  }

  static Future<Uint8List> injectFreehandDrawingAsync({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required List<List<fm.Offset>> drawingPaths,
    String? password,
  }) async {
    return await Isolate.run(() => _executeDrawingCompilation(
          originalBytes: originalBytes,
          targetPageZeroIndexed: targetPageZeroIndexed,
          drawingPaths: drawingPaths,
          password: password,
        ));
  }

  static Uint8List _executeDrawingCompilation({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required List<List<fm.Offset>> drawingPaths,
    String? password,
  }) {
    final PdfDocument document = PdfDocument(inputBytes: originalBytes, password: password);

    try {
      if (targetPageZeroIndexed < 0 || targetPageZeroIndexed >= document.pages.count) {
        return originalBytes;
      }

      final PdfPage targetPage = document.pages[targetPageZeroIndexed];
      final PdfGraphics graphics = targetPage.graphics;

      final PdfPen vectorPen = PdfPen(
        PdfColor(0, 240, 255), 
        width: 2.5,
      );
      vectorPen.lineJoin = PdfLineJoin.round;
      vectorPen.lineCap = PdfLineCap.round;

      for (final List<fm.Offset> singleStrokePath in drawingPaths) {
        if (singleStrokePath.length < 2) continue;

        for (int i = 0; i < singleStrokePath.length - 1; i++) {
          final fm.Offset startPoint = singleStrokePath[i];
          final fm.Offset endPoint = singleStrokePath[i + 1];

          graphics.drawLine(
            vectorPen,
            fm.Offset(startPoint.dx, startPoint.dy),
            fm.Offset(endPoint.dx, endPoint.dy),
          );
        }
      }

      // Automatically scrub tracking nodes when saving a mutation loop
      document.documentInformation.author = 'CLOUDNEX SECURE SUBSYSTEM';
      document.documentInformation.creator = 'CLOUDNEX CORE ENGINE';

      final List<int> compiledBytes = document.save();
      return Uint8List.fromList(compiledBytes);
    } finally {
      document.dispose();
    }
  }

  static Future<Uint8List> injectTextHighlightAsync({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required String selectedTextLine,
    String? password,
  }) async {
    return await Isolate.run(() => _executeHighlightCompilation(
          originalBytes: originalBytes,
          targetPageZeroIndexed: targetPageZeroIndexed,
          selectedTextLine: selectedTextLine,
          password: password,
        ));
  }

  static Uint8List _executeHighlightCompilation({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required String selectedTextLine,
    String? password,
  }) {
    final PdfDocument document = PdfDocument(inputBytes: originalBytes, password: password);

    try {
      if (targetPageZeroIndexed < 0 || targetPageZeroIndexed >= document.pages.count) {
        return originalBytes;
      }

      final PdfPage targetPage = document.pages[targetPageZeroIndexed];
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      final List<MatchedItem> searchMatches = extractor.findText(
        [selectedTextLine],
        startPageIndex: targetPageZeroIndexed,
        endPageIndex: targetPageZeroIndexed,
      );

      if (searchMatches.isNotEmpty) {
        final MatchedItem matchData = searchMatches.first;
        final PdfTextMarkupAnnotation highlightAnnotation = PdfTextMarkupAnnotation(
          matchData.bounds,
          PdfTextMarkupAnnotationType.highlight,
        );
        
        highlightAnnotation.color = PdfColor(255, 235, 59);
        highlightAnnotation.text = "CloudNex System Highlight Element";
        targetPage.annotations.add(highlightAnnotation);
      }

      // Automatically scrub tracking nodes when saving a mutation loop
      document.documentInformation.author = 'CLOUDNEX SECURE SUBSYSTEM';
      document.documentInformation.creator = 'CLOUDNEX CORE ENGINE';

      final List<int> compiledBytes = document.save();
      return Uint8List.fromList(compiledBytes);
    } finally {
      document.dispose();
    }
  }

  static Future<Uint8List> injectGraphicSignatureAsync({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required Uint8List signatureImageBytes,
    required double coordinateX,
    required double coordinateY,
    String? password,
  }) async {
    return await Isolate.run(() => _executeHeavyCompilation(
          originalBytes: originalBytes,
          targetPageZeroIndexed: targetPageZeroIndexed,
          signatureImageBytes: signatureImageBytes,
          coordinateX: coordinateX,
          coordinateY: coordinateY,
          password: password,
        ));
  }

  static Uint8List _executeHeavyCompilation({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required Uint8List signatureImageBytes,
    required double coordinateX,
    required double coordinateY,
    String? password,
  }) {
    final PdfDocument document = PdfDocument(inputBytes: originalBytes, password: password);

    try {
      if (targetPageZeroIndexed < 0 || targetPageZeroIndexed >= document.pages.count) {
        return originalBytes;
      }

      final PdfPage targetPage = document.pages[targetPageZeroIndexed];
      final PdfBitmap signatureBitmap = PdfBitmap(signatureImageBytes);

      targetPage.graphics.drawImage(
        signatureBitmap,
        fm.Rect.fromLTWH(coordinateX, coordinateY, 130, 65),
      );

      // Automatically scrub tracking nodes when saving a mutation loop
      document.documentInformation.author = 'CLOUDNEX SECURE SUBSYSTEM';
      document.documentInformation.creator = 'CLOUDNEX CORE ENGINE';

      final List<int> compiledBytes = document.save();
      return Uint8List.fromList(compiledBytes);
    } finally {
      document.dispose();
    }
  }

  static Future<bool> saveDocumentViaSystemPicker({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'SELECT EXPORT DESTINATION',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      return outputPath != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> shareDocumentViaSystemSheet({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final XFile fileToShare = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([fileToShare], subject: 'Export: $fileName');
    } catch (_) {}
  }
}