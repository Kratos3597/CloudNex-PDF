import 'dart:foundation';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfModifierService {
  PdfModifierService._();

  /// Checks if a document matrix is locked behind cryptographic encryption keys
  static bool isDocumentEncrypted(Uint8List bytes) {
    try {
      // Attempt a shallow structural read; throws an exception instantly if encrypted
      PdfDocument.getStructure(bytes);
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Verifies if a cryptographic security password can successfully open the document
  static bool validatePassword(Uint8List bytes, String password) {
    try {
      final PdfDocument doc = PdfDocument(inputBytes: bytes, password: password);
      doc.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// MAIN THREAD SECURE ENTRYPOINT
  static Future<Uint8List> injectGraphicSignatureAsync({
    required Uint8List originalBytes,
    required int targetPageZeroIndexed,
    required Uint8List signatureImageBytes,
    required double coordinateX,
    required double coordinateY,
    String? password, // Pass decryption keys safely down to the background isolate
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

  /// BACKGROUND SECURE WORKER MATRIX
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
        Rect.fromLTWH(coordinateX, coordinateY, 130, 65),
      );

      // ==========================================
      // 🔒 POINT 9 PRIVACY SANITATION SCRUBBER
      // ==========================================
      document.documentInformation.author = 'CLOUDNEX SECURE SUBSYSTEM';
      document.documentInformation.creator = 'CLOUDNEX CORE ENGINE';
      document.documentInformation.producer = 'CLOUDNEX COMPILER';
      document.documentInformation.title = 'SANITIZED MATRIX';
      document.documentInformation.subject = 'SECURE EXPORT';
      document.documentInformation.keywords = 'SCRUBBED';
      
      // Clear out deep underlying custom tracking metadata schemas
      document.documentInformation.clear();

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