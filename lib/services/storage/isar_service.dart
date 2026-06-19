import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/library/domain/models/document_record.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal() {
    db = openDB();
  }

  late Future<Isar> db;

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [DocumentRecordSchema],
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

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
}
