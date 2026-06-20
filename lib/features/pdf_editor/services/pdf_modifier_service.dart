import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
      final PdfDocument doc = PdfDocument(inputBytes: bytes);
      doc.dispose();
      return false; 
    } catch (_) {
      return true; 
    }
  }

  static bool validatePassword(Uint8List bytes, String password) {
    try {
      final PdfDocument doc =
      PdfDocument(inputBytes: bytes, password: password);
      doc.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  static PdfSecurityReport analyzeDocumentStructure(
      Uint8List bytes, [
        String? password,
      ]) {
    PdfDocument? document;

    try {
      document = PdfDocument(inputBytes: bytes, password: password);

      const bool isEncrypted = false; 

      final int totalPages = document.pages.count;

      final String author = document.documentInformation.author.isEmpty
          ? 'UNVERIFIED'
          : document.documentInformation.author;

      return PdfSecurityReport(
        isEncrypted: isEncrypted,
        totalPages: totalPages,
        authorSignature: author,
        complianceStatus: 'OK',
        permissionsValid: true,
      );
    } catch (_) {
      return PdfSecurityReport(
        isEncrypted: true,
        totalPages: 0,
        authorSignature: 'LOCKED',
        complianceStatus: 'FAILED',
        permissionsValid: false,
      );
    } finally {
      document?.dispose();
    }
  }

  static Future<Uint8List> injectGraphicSignatureAsync({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required Uint8List signatureImageBytes,
    required fm.Rect bounds,
    String? password,
  }) async {
    return await Isolate.run(() => _executeHeavyCompilation(
      originalBytes,
      targetPageZeroIndexed,
      signatureImageBytes,
      bounds,
      password,
    ));
  }

  static Uint8List _executeHeavyCompilation(
      Uint8List bytes,
      int page,
      Uint8List sig,
      fm.Rect bounds,
      String? password,
      ) {
    PdfDocument? doc;
    try {
      doc = PdfDocument(inputBytes: bytes, password: password);
      
      if (page < 0 || page >= doc.pages.count) {
        throw Exception('Page index out of range');
      }

      final PdfPage pdfPage = doc.pages[page];
      
      pdfPage.graphics.drawImage(
        PdfBitmap(sig),
        bounds,
      );

      final List<int> saved = doc.saveSync();
      return Uint8List.fromList(saved);
    } catch (e) {
      rethrow;
    } finally {
      doc?.dispose();
    }
  }

  static Future<bool> saveDocumentViaSystemPicker({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    final String? path = await FilePicker.platform.saveFile(
      fileName: suggestedName,
      bytes: bytes,
    );

    return path != null;
  }

  static Future<bool> saveTextDataViaPicker({
    required String text,
    required String suggestedName,
  }) async {
    final Uint8List bytes = Uint8List.fromList(text.codeUnits);
    final String? path = await FilePicker.platform.saveFile(
      fileName: suggestedName,
      bytes: bytes,
    );
    return path != null;
  }

  static Future<void> shareDocumentViaSystemSheet({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/pdf',
      )
    ]);
  }
}
