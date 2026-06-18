import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_cache_service.dart';

import '../services/pdf_modifier_service.dart';

enum ActivePdfTool { none, draw, highlight, signaturePlacement, imagePlacement }

class PdfStateController extends ChangeNotifier {
  Uint8List? _currentBytes;
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];

  final PdfViewerController pdfViewerController = PdfViewerController();
  int _activePageNumber = 1;

  ActivePdfTool _currentTool = ActivePdfTool.none;
  Uint8List? _activeSignatureGraphicBytes;
  String? _activeDocumentPassword;
  
  PdfSecurityReport? _securityReport;

  Uint8List? get currentBytes => _currentBytes;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get activePageNumber => _activePageNumber;
  ActivePdfTool get currentTool => _currentTool;
  bool get isViewportLocked => _currentTool != ActivePdfTool.none;
  Uint8List? get activeSignatureGraphicBytes => _activeSignatureGraphicBytes;
  String? get activeDocumentPassword => _activeDocumentPassword;
  PdfSecurityReport? get securityReport => _securityReport;

  void loadDocument(Uint8List initialBytes,
      {String? password, int initialPage = 1}) {
    _currentBytes = initialBytes;
    _activeDocumentPassword = password;
    _activePageNumber = initialPage;
    _undoStack.clear();
    _redoStack.clear();
    _currentTool = ActivePdfTool.none;
    _activeSignatureGraphicBytes = null;
    
    _updateSecurityReport();

    // Synergize instantly onto disk caching files
    _triggerBackgroundCacheSync();
    notifyListeners();
  }

  void _updateSecurityReport() {
    if (_currentBytes != null) {
      _securityReport = PdfModifierService.analyzeDocumentStructure(
        _currentBytes!,
        _activeDocumentPassword,
      );
    }
  }

  void setupSignaturePlacement(Uint8List graphicBytes) {
    _activeSignatureGraphicBytes = graphicBytes;
    _currentTool = ActivePdfTool.signaturePlacement;
    notifyListeners();
  }

  void setupImagePlacement(Uint8List imageBytes) {
    _activeSignatureGraphicBytes = imageBytes;
    _currentTool = ActivePdfTool.imagePlacement;
    notifyListeners();
  }

  void toggleTool(ActivePdfTool tool) {
    if (_currentTool == tool) {
      _currentTool = ActivePdfTool.none;
    } else {
      _currentTool = tool;
    }
    notifyListeners();
  }

  void clearActiveTool() {
    _currentTool = ActivePdfTool.none;
    _activeSignatureGraphicBytes = null;
    notifyListeners();
  }

  void updatePageNumber(int pageNum) {
    if (_activePageNumber == pageNum) return;
    _activePageNumber = pageNum;
    _triggerBackgroundCacheSync();
    notifyListeners();
  }

  void commitMutation(Uint8List mutatedBytes) {
    if (_currentBytes != null) {
      _undoStack.add(_currentBytes!);
    }
    _currentBytes = mutatedBytes;
    _redoStack.clear();
    _updateSecurityReport();
    _triggerBackgroundCacheSync();
    notifyListeners();
  }

  /// Triggers a non-blocking background write out to disk files
  void _triggerBackgroundCacheSync() {
    if (_currentBytes == null) return;
    PdfCacheService.writeRecoverySession(
      bytes: _currentBytes!,
      activePage: _activePageNumber,
      password: _activeDocumentPassword,
    );
  }

  /// Invoked when exporting or exiting intentionally to destroy session remnants
  void clearActiveSessionCache() {
    PdfCacheService.purgeRecoverySession();
  }

  void undo() {
    if (!canUndo) return;
    final previousState = _undoStack.removeLast();
    if (_currentBytes != null) {
      _redoStack.add(_currentBytes!);
    }
    _currentBytes = previousState;
    _triggerBackgroundCacheSync();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final nextState = _redoStack.removeLast();
    if (_currentBytes != null) {
      _undoStack.add(_currentBytes!);
    }
    _currentBytes = nextState;
    _triggerBackgroundCacheSync();
    notifyListeners();
  }

  @override
  void dispose() {
    pdfViewerController.dispose();
    _undoStack.clear();
    _redoStack.clear();
    _currentBytes = null;
    _activeSignatureGraphicBytes = null;
    _activeDocumentPassword = null;
    super.dispose();
  }
}