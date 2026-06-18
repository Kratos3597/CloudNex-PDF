import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage/isar_service.dart';
import '../../features/library/domain/models/document_record.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final documentListProvider = FutureProvider<List<DocumentRecord>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllDocuments();
});
