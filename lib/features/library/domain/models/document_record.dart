import 'package:isar/isar.dart';

part 'document_record.g.dart';

@collection
class DocumentRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String filePath;

  late String fileName;

  int lastOpenedPage = 0;

  double lastZoomLevel = 1.0;

  DateTime lastOpenedDate = DateTime.now();

  String? thumbnailPath;

  bool isFavorite = false;

  List<String>? tags;

  String? summary; // For AI insights
}
