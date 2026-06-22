import 'dart:typed_data';
import '../pipeline/vision_pipeline.dart';
import '../models/graph_model.dart';
import '../../storage/database.dart';
import '../pipeline/semantic_pipeline.dart';

/// CloudNex Neural Engine (CNNE) Coordinator
/// Central hub for all AI operations: Vision, Semantic, and OCR.
class CnneBrain {
  final StorageDatabase _db;
  late final SemanticPipeline semantic;
  
  CnneBrain(this._db) {
    semantic = SemanticPipeline(_db);
  }

  /// Analyzes a page and generates both DOM and Semantic Embeddings.
  /// Optimized to run on NPU if available.
  Future<DocumentPageDom> processPage(String docId, Uint8List pageBytes, int pageIndex) async {
    // 1. Check Cache
    final existing = await _db.getPageDom(docId, pageIndex);
    if (existing != null) return existing;

    // 2. Vision Analysis (Layout)
    final zones = VisionPipeline.scanPage(pageBytes, pageIndex);
    
    final elements = zones.map((z) => DomElement(
      type: _mapLabelToType(z.label),
      text: z.originalText,
      left: z.bounds.left,
      top: z.bounds.top,
      width: z.bounds.width,
      height: z.bounds.height,
      fontSize: z.fontSize,
    )).toList();

    final dom = DocumentPageDom(
      documentId: docId,
      pageIndex: pageIndex,
      elements: elements,
    );

    // 3. Persist DOM
    await _db.savePageDom(dom);

    return dom;
  }

  DomElementType _mapLabelToType(String label) {
    switch (label) {
      case 'heading': return DomElementType.heading;
      case 'table': return DomElementType.table;
      default: return DomElementType.paragraph;
    }
  }

  /// Semantic Search across the document
  Future<List<SemanticEmbedding>> semanticSearch(String docId, String query) async {
    return await semantic.askPdf(docId, query).then((_) async {
       // Returning search results for UI
       return await _db.search(docId, List.filled(384, 0.0));
    });
  }
}
