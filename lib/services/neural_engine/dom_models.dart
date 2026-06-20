import 'dart:ui';
import 'package:isar/isar.dart';

part 'dom_models.g.dart';

/// Document Object Model (DOM) - Represents the semantic structure of a PDF page.
@collection
class DocumentPageDom {
  Id id = Isar.autoIncrement;

  @Index()
  final String documentId;

  @Index()
  final int pageIndex;

  final List<DomElement> elements;

  DocumentPageDom({
    required this.documentId,
    required this.pageIndex,
    required this.elements,
  });
}

@embedded
class DomElement {
  @enumerated
  DomElementType type;

  String? text;
  
  double left;
  double top;
  double width;
  double height;

  double? fontSize;
  String? fontFamily;
  
  // For semantic search: Embedding vector index reference
  int? embeddingId;

  DomElement({
    this.type = DomElementType.paragraph,
    this.text,
    this.left = 0,
    this.top = 0,
    this.width = 0,
    this.height = 0,
    this.fontSize,
    this.fontFamily,
    this.embeddingId,
  });

  @ignore
  Rect get bounds => Rect.fromLTWH(left, top, width, height);
}

enum DomElementType {
  title,
  heading,
  paragraph,
  table,
  image,
  formField,
  signature,
  footnote,
  list
}

/// Vector Embedding record for Semantic Search
@collection
class SemanticEmbedding {
  Id id = Isar.autoIncrement;

  @Index()
  final String documentId;

  final String content;
  
  // Flattened Float32List for Isar storage
  final List<double> vector;

  @Index()
  final int pageIndex;

  SemanticEmbedding({
    required this.documentId,
    required this.content,
    required this.vector,
    required this.pageIndex,
  });
}
