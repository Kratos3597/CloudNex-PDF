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

  // ✅ FIX: correct encryption detection (24.2.3)
  static bool isDocumentEncrypted(Uint8List bytes) {
    final PdfDocument doc = PdfDocument(inputBytes: bytes);

    final bool isEncrypted = doc.isEncrypted;

    doc.dispose();
    return isEncrypted;
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

      final bool isEncrypted = document.isEncrypted;

      final PdfPermissions permissions = document.security.permissions;

      // ✅ FIX: no .value, use flag check instead
      final bool canPrint =
          permissions.getValue(PdfPermissionsFlags.print);

      return PdfSecurityReport(
        isEncrypted: isEncrypted,
        totalPages: document.pages.count,
        authorSignature:
            document.documentInformation.author ?? 'UNVERIFIED',
        complianceStatus: 'OK',
        permissionsValid: canPrint,
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
    required double coordinateX,
    required double coordinateY,
    String? password,
  }) async {
    return await Isolate.run(() => _executeHeavyCompilation(
          originalBytes,
          targetPageZeroIndexed,
          signatureImageBytes,
          coordinateX,
          coordinateY,
          password,
        ));
  }

  static Uint8List _executeHeavyCompilation(
    Uint8List bytes,
    int page,
    Uint8List sig,
    double x,
    double y,
    String? password,
  ) {
    final PdfDocument doc =
        PdfDocument(inputBytes: bytes, password: password);

    try {
      doc.pages[page].graphics.drawImage(
        PdfBitmap(sig),
        fm.Rect.fromLTWH(x, y, 130, 65),
      );

      final List<int> saved = doc.saveSync();
      return Uint8List.fromList(saved);
    } finally {
      doc.dispose();
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