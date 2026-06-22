import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/document_model.dart';
import '../ai/models/graph_model.dart';
import 'dart:math' as math;

class StorageDatabase {
  static final StorageDatabase _instance = StorageDatabase._internal();
  factory StorageDatabase() => _instance;
  StorageDatabase._internal();

  late Future<Isar> db = _initDb();

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          DocumentRecordSchema, // Keeping existing Schema names for compatibility
          DocumentPageDomSchema,
          SemanticEmbeddingSchema,
        ],
        directory: dir.path,
        name: 'cloudnex_db',
      );
    }
    return Isar.getInstance('cloudnex_db') ?? Isar.getInstance()!;
  }

  // --- Document Methods ---

  Future<void> saveDocument(DocumentRecord record) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.documentRecords.put(record);
    });
  }

  Future<List<DocumentRecord>> getAllDocuments() async {
    final isar = await db;
    return await isar.documentRecords.where().sortByLastOpenedDateDesc().findAll();
  }

  Future<DocumentRecord?> getDocumentByPath(String path) async {
    final isar = await db;
    return await isar.documentRecords.filter().filePathEqualTo(path).findFirst();
  }

  Future<void> updateLastOpenedPage(String path, int page) async {
    final isar = await db;
    final record = await isar.documentRecords.filter().filePathEqualTo(path).findFirst();
    if (record != null) {
      record.lastOpenedPage = page;
      record.lastOpenedDate = DateTime.now();
      await isar.writeTxn(() async {
        await isar.documentRecords.put(record);
      });
    }
  }

  Future<void> deleteDocument(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.documentRecords.delete(id);
    });
  }

  // --- AI / Graph Methods ---

  Future<void> savePageDom(DocumentPageDom dom) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.documentPageDoms.put(dom);
    });
  }

  Future<DocumentPageDom?> getPageDom(String docId, int pageIndex) async {
    final isar = await db;
    return await isar.documentPageDoms
        .filter()
        .documentIdEqualTo(docId)
        .pageIndexEqualTo(pageIndex)
        .findFirst();
  }

  // --- Vector Methods ---

  Future<void> addEmbedding(SemanticEmbedding embedding) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.semanticEmbeddings.put(embedding);
    });
  }

  Future<List<SemanticEmbedding>> search(String docId, List<double> queryVector, {int limit = 5}) async {
    final isar = await db;
    
    final all = await isar.semanticEmbeddings
        .filter()
        .documentIdEqualTo(docId)
        .findAll();

    if (all.isEmpty) return [];

    all.sort((a, b) => _calculateSimilarity(b.vector, queryVector)
        .compareTo(_calculateSimilarity(a.vector, queryVector)));

    return all.take(limit).toList();
  }

  double _calculateSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 0;
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
}
