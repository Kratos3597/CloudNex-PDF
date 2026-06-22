import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../engine/memory/memory_manager.dart';
import '../../engine/edit/edit_engine.dart';
import 'analytics_service.dart';
import '../../storage/graph/overlay_model.dart';
import '../../ai/brain/cnne_brain.dart';
import '../../storage/database.dart';
import '../../ai/models/graph_model.dart';

enum ActivePdfTool { none, highlight, underline, strikeout, ink, rectangle, circle, signaturePlacement, textPlacement, select }

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

  // AI DOM Cache
  final Map<int, DocumentPageDom> pageDoms = {};

  // SHADOW LAYER: Live interactive objects that are not yet burned into the PDF
  final List<ShadowObject> shadowObjects = [];

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

class AppState extends ChangeNotifier {
  PdfSession? _activeSession;
  bool _isEditMode = false;

  ActivePdfTool _currentTool = ActivePdfTool.none;
  Uint8List? _activeSignatureGraphicBytes;
  String? _selectedShadowObjectId;

  // Unified Database Service
  final StorageDatabase db = StorageDatabase();

  // CNNE AI Service
  late final CnneBrain ai;

  AppState() {
    ai = CnneBrain(db);
  }

  PdfSession? get activeSession => _activeSession;

  Uint8List? get currentBytes => _activeSession?.currentBytes;
  bool get canUndo => _activeSession?.undoStack.isNotEmpty ?? false;
  bool get canRedo => _activeSession?.redoStack.isNotEmpty ?? false;
  int get activePageNumber => _activeSession?.activePageNumber ?? 1;
  PdfViewerController? get pdfViewerController => _activeSession?.pdfViewerController;
  
  ActivePdfTool get currentTool => _currentTool;
  bool get isEditMode => _isEditMode;
  bool get isViewportLocked => (_currentTool != ActivePdfTool.none && _currentTool != ActivePdfTool.select) || _isEditMode;
  Uint8List? get activeSignatureGraphicBytes => _activeSignatureGraphicBytes;
  String? get activeDocumentPassword => _activeSession?.password;
  PdfSecurityReport? get securityReport => _activeSession?.securityReport;

  List<ShadowObject> get activeShadowObjects => _activeSession?.shadowObjects ?? [];
  String? get selectedShadowObjectId => _selectedShadowObjectId;

  void openDocument(Uint8List bytes, String fileName, {String? filePath, String? password, int initialPage = 1}) {
    // Close existing session before opening a new one
    _activeSession?.dispose();
    
    _activeSession = PdfSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      filePath: filePath,
      currentBytes: bytes,
      password: password,
    );
    _activeSession!.activePageNumber = initialPage;
    
    _updateSecurityReport(_activeSession!);
    _triggerBackgroundCacheSync(_activeSession!);
    _triggerAiAnalysis(_activeSession!, initialPage - 1);
    
    analyticsService.logAction("OPEN_DOCUMENT", fileName);
    notifyListeners();
  }

  Future<void> _triggerAiAnalysis(PdfSession session, int pageIndex) async {
    if (session.currentBytes == null || session.pageDoms.containsKey(pageIndex)) return;
    
    final dom = await ai.processPage(session.id, session.currentBytes!, pageIndex);
    session.pageDoms[pageIndex] = dom;
    notifyListeners();
  }

  // SHADOW LAYER METHODS
  void addShadowObject(ShadowObject obj) {
    _activeSession?.shadowObjects.add(obj);
    _selectedShadowObjectId = obj.id;
    notifyListeners();
  }

  void updateShadowObject(ShadowObject obj) {
    if (_activeSession == null) return;
    final index = _activeSession!.shadowObjects.indexWhere((o) => o.id == obj.id);
    if (index != -1) {
      _activeSession!.shadowObjects[index] = obj;
      notifyListeners();
    }
  }

  void selectShadowObject(String? id) {
    _selectedShadowObjectId = id;
    if (id != null) _currentTool = ActivePdfTool.select;
    notifyListeners();
  }

  void removeShadowObject(String id) {
    _activeSession?.shadowObjects.removeWhere((o) => o.id == id);
    if (_selectedShadowObjectId == id) _selectedShadowObjectId = null;
    notifyListeners();
  }

  void closeSession() {
    _activeSession?.dispose();
    _activeSession = null;
    _isEditMode = false;
    _currentTool = ActivePdfTool.none;
    notifyListeners();
  }

  void _updateSecurityReport(PdfSession session) {
    if (session.currentBytes != null) {
      session.securityReport = EditEngine.analyzeDocumentStructure(
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

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (!_isEditMode) {
      _currentTool = ActivePdfTool.none;
    }
    notifyListeners();
  }

  void clearActiveTool() {
    _currentTool = ActivePdfTool.none;
    _activeSignatureGraphicBytes = null;
    _selectedShadowObjectId = null;
    notifyListeners();
  }

  void updatePageNumber(int pageNum) {
    if (_activeSession == null || _activeSession!.activePageNumber == pageNum) return;
    _activeSession!.activePageNumber = pageNum;
    
    if (_activeSession!.filePath != null) {
      db.updateLastOpenedPage(_activeSession!.filePath!, pageNum);
    }

    _triggerBackgroundCacheSync(_activeSession!);
    _triggerAiAnalysis(_activeSession!, pageNum - 1);
    notifyListeners();
  }

  void commitMutation(Uint8List mutatedBytes) {
    if (_activeSession == null) return;

    if (_activeSession!.currentBytes != null) {
      _activeSession!.undoStack.add(_activeSession!.currentBytes!);
    }
    _activeSession!.currentBytes = mutatedBytes;
    
    _activeSession!.liveDocument?.dispose();
    _activeSession!.liveDocument = sf.PdfDocument(inputBytes: mutatedBytes, password: _activeSession!.password);

    _activeSession!.redoStack.clear();
    _activeSession!.pageDoms.clear(); // Invalidate AI cache as bytes changed
    _updateSecurityReport(_activeSession!);
    _triggerBackgroundCacheSync(_activeSession!);
    _triggerAiAnalysis(_activeSession!, _activeSession!.activePageNumber - 1);
    
    analyticsService.logAction("MODIFY_DOCUMENT", _activeSession!.fileName);
    notifyListeners();
  }

  void _triggerBackgroundCacheSync(PdfSession session) {
    if (session.currentBytes == null) return;
    MemoryManager.writeRecoverySession(
      bytes: session.currentBytes!,
      activePage: session.activePageNumber,
      password: session.password,
    );
  }

  void clearActiveSessionCache() {
    MemoryManager.purgeRecoverySession();
  }

  void undo() {
    if (_activeSession == null || _activeSession!.undoStack.isEmpty) return;
    
    final previousState = _activeSession!.undoStack.removeLast();
    if (_activeSession!.currentBytes != null) {
      _activeSession!.redoStack.add(_activeSession!.currentBytes!);
    }
    _activeSession!.currentBytes = previousState;
    _triggerBackgroundCacheSync(_activeSession!);
    notifyListeners();
  }

  void redo() {
    if (_activeSession == null || _activeSession!.redoStack.isEmpty) return;

    final nextState = _activeSession!.redoStack.removeLast();
    if (_activeSession!.currentBytes != null) {
      _activeSession!.undoStack.add(_activeSession!.currentBytes!);
    }
    _activeSession!.currentBytes = nextState;
    _triggerBackgroundCacheSync(_activeSession!);
    notifyListeners();
  }

  @override
  void dispose() {
    _activeSession?.dispose();
    super.dispose();
  }
}
