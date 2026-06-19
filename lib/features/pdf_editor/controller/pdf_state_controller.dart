import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../services/pdf_cache_service.dart';
import '../services/pdf_modifier_service.dart';
import 'package:cloudnex_pdf_reader/features/analytics/services/analytics_service.dart';
import 'package:cloudnex_pdf_reader/services/storage/isar_service.dart';

enum ActivePdfTool { none, highlight, underline, strikeout, ink, rectangle, circle, signaturePlacement, textPlacement }

class PdfSession {
  final String id;
  final String fileName;
  final String? filePath;
  Uint8List? currentBytes;
  sf.PdfDocument? liveDocument; 
  final List<Uint8List> undoStack = [];
  final List<Uint8List> redoStack = [];
  final PdfViewerController pdfViewerController = PdfViewerController();
  int activePageNumber = 1;
  String? password;
  PdfSecurityReport? securityReport;

  PdfSession({
    required this.id,
    required this.fileName,
    this.filePath,
    this.currentBytes,
    this.password,
  }) {
    if (currentBytes != null) {
      liveDocument = sf.PdfDocument(inputBytes: currentBytes, password: password);
    }
  }

  void dispose() {
    pdfViewerController.dispose();
    liveDocument?.dispose();
  }

  void refreshBytes() {
    if (liveDocument != null) {
      final List<int> saved = liveDocument!.saveSync();
      currentBytes = Uint8List.fromList(saved);
    }
  }
}

class PdfStateController extends ChangeNotifier {
  final List<PdfSession> _sessions = [];
  int _activeSessionIndex = -1;

  ActivePdfTool _currentTool = ActivePdfTool.none;
  Uint8List? _activeSignatureGraphicBytes;

  List<PdfSession> get sessions => _sessions;
  int get activeSessionIndex => _activeSessionIndex;
  
  PdfSession? get activeSession => 
      (_activeSessionIndex >= 0 && _activeSessionIndex < _sessions.length) 
      ? _sessions[_activeSessionIndex] : null;

  Uint8List? get currentBytes => activeSession?.currentBytes;
  bool get canUndo => activeSession?.undoStack.isNotEmpty ?? false;
  bool get canRedo => activeSession?.redoStack.isNotEmpty ?? false;
  int get activePageNumber => activeSession?.activePageNumber ?? 1;
  PdfViewerController? get pdfViewerController => activeSession?.pdfViewerController;
  
  ActivePdfTool get currentTool => _currentTool;
  bool get isViewportLocked => _currentTool != ActivePdfTool.none;
  Uint8List? get activeSignatureGraphicBytes => _activeSignatureGraphicBytes;
  String? get activeDocumentPassword => activeSession?.password;
  PdfSecurityReport? get securityReport => activeSession?.securityReport;

  void openDocument(Uint8List bytes, String fileName, {String? filePath, String? password, int initialPage = 1}) {
    final session = PdfSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      filePath: filePath,
      currentBytes: bytes,
      password: password,
    );
    session.activePageNumber = initialPage;
    
    _sessions.add(session);
    _activeSessionIndex = _sessions.length - 1;
    _updateSecurityReport(session);
    _triggerBackgroundCacheSync(session);
    
    analyticsService.logAction("OPEN_DOCUMENT", fileName);
    notifyListeners();
  }

  void closeSession(int index) {
    if (index < 0 || index >= _sessions.length) return;
    
    final session = _sessions.removeAt(index);
    session.dispose();
    
    if (_activeSessionIndex >= _sessions.length) {
      _activeSessionIndex = _sessions.length - 1;
    }
    
    if (_sessions.isEmpty) {
      _activeSessionIndex = -1;
    }
    
    notifyListeners();
  }

  void switchToSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeSessionIndex = index;
      notifyListeners();
    }
  }

  void _updateSecurityReport(PdfSession session) {
    if (session.currentBytes != null) {
      session.securityReport = PdfModifierService.analyzeDocumentStructure(
        session.currentBytes!,
        session.password,
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
    // For now, mapping image placement to signature placement for the overlay
    _currentTool = ActivePdfTool.signaturePlacement;
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
    final session = activeSession;
    if (session == null || session.activePageNumber == pageNum) return;
    session.activePageNumber = pageNum;
    
    if (session.filePath != null) {
      IsarService().updateLastOpenedPage(session.filePath!, pageNum);
    }

    _triggerBackgroundCacheSync(session);
    notifyListeners();
  }

  void commitMutation(Uint8List mutatedBytes) {
    final session = activeSession;
    if (session == null) return;

    if (session.currentBytes != null) {
      session.undoStack.add(session.currentBytes!);
    }
    session.currentBytes = mutatedBytes;
    
    session.liveDocument?.dispose();
    session.liveDocument = sf.PdfDocument(inputBytes: mutatedBytes, password: session.password);

    session.redoStack.clear();
    _updateSecurityReport(session);
    _triggerBackgroundCacheSync(session);
    
    analyticsService.logAction("MODIFY_DOCUMENT", session.fileName);
    notifyListeners();
  }

  void _triggerBackgroundCacheSync(PdfSession session) {
    if (session.currentBytes == null) return;
    PdfCacheService.writeRecoverySession(
      bytes: session.currentBytes!,
      activePage: session.activePageNumber,
      password: session.password,
    );
  }

  void clearActiveSessionCache() {
    PdfCacheService.purgeRecoverySession();
  }

  void undo() {
    final session = activeSession;
    if (session == null || session.undoStack.isEmpty) return;
    
    final previousState = session.undoStack.removeLast();
    if (session.currentBytes != null) {
      session.redoStack.add(session.currentBytes!);
    }
    session.currentBytes = previousState;
    _triggerBackgroundCacheSync(session);
    notifyListeners();
  }

  void redo() {
    final session = activeSession;
    if (session == null || session.redoStack.isEmpty) return;

    final nextState = session.redoStack.removeLast();
    if (session.currentBytes != null) {
      session.undoStack.add(session.currentBytes!);
    }
    session.currentBytes = nextState;
    _triggerBackgroundCacheSync(session);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }
}
