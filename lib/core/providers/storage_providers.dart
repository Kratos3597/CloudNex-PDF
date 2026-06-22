import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/database.dart';
import '../../storage/models/document_model.dart';

final databaseProvider = Provider<StorageDatabase>((ref) {
  return StorageDatabase();
});

final documentListProvider = FutureProvider<List<DocumentRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllDocuments();
});
