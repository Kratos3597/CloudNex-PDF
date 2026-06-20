import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage/cloudnex_database.dart';
import '../../features/library/domain/models/document_record.dart';

final databaseProvider = Provider<CloudNexDatabase>((ref) {
  return CloudNexDatabase();
});

final documentListProvider = FutureProvider<List<DocumentRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllDocuments();
});
