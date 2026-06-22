import 'package:isar/isar.dart';

part 'document_model.g.dart';

@collection
class DocumentRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String filePath;

  late String fileName;
  
  late DateTime lastOpenedDate;
  
  int lastOpenedPage = 1;

  DocumentRecord();
}
