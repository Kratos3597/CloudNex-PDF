import 'dart:io';
import 'package:flutter/material.dart';
import 'services/pdf_service.dart';

class PdfProvider extends ChangeNotifier {
  final PdfService _pdfService = PdfService();
  File? _selectedFile;

  File? get selectedFile => _selectedFile;

  Future<void> pickAndLoadPdf() async {
    final file = await _pdfService.pickPdfFile();
    if (file != null) {
      _selectedFile = file;
      notifyListeners(); // This tells the UI to rebuild
    }
  }
}