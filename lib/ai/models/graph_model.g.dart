// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDocumentPageDomCollection on Isar {
  IsarCollection<DocumentPageDom> get documentPageDoms => this.collection();
}

const DocumentPageDomSchema = CollectionSchema(
  name: r'DocumentPageDom',
  id: -5540487932424306384,
  properties: {
    r'documentId': PropertySchema(
      id: 0,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'elements': PropertySchema(
      id: 1,
      name: r'elements',
      type: IsarType.objectList,
      target: r'DomElement',
    ),
    r'pageIndex': PropertySchema(
      id: 2,
      name: r'pageIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _documentPageDomEstimateSize,
  serialize: _documentPageDomSerialize,
  deserialize: _documentPageDomDeserialize,
  deserializeProp: _documentPageDomDeserializeProp,
  idName: r'id',
  indexes: {
    r'documentId': IndexSchema(
      id: 4187168439921340405,
      name: r'documentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'pageIndex': IndexSchema(
      id: -6792988718546572558,
      name: r'pageIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pageIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'DomElement': DomElementSchema},
  getId: _documentPageDomGetId,
  getLinks: _documentPageDomGetLinks,
  attach: _documentPageDomAttach,
  version: '3.1.0+1',
);

int _documentPageDomEstimateSize(
  DocumentPageDom object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.elements.length * 3;
  {
    final offsets = allOffsets[DomElement]!;
    for (var i = 0; i < object.elements.length; i++) {
      final value = object.elements[i];
      bytesCount += DomElementSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _documentPageDomSerialize(
  DocumentPageDom object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.documentId);
  writer.writeObjectList<DomElement>(
    offsets[1],
    allOffsets,
    DomElementSchema.serialize,
    object.elements,
  );
  writer.writeLong(offsets[2], object.pageIndex);
}

DocumentPageDom _documentPageDomDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DocumentPageDom(
    documentId: reader.readString(offsets[0]),
    elements: reader.readObjectList<DomElement>(
          offsets[1],
          DomElementSchema.deserialize,
          allOffsets,
          DomElement(),
        ) ??
        [],
    pageIndex: reader.readLong(offsets[2]),
  );
  object.id = id;
  return object;
}

P _documentPageDomDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readObjectList<DomElement>(
            offset,
            DomElementSchema.deserialize,
            allOffsets,
            DomElement(),
          ) ??
          []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _documentPageDomGetId(DocumentPageDom object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _documentPageDomGetLinks(DocumentPageDom object) {
  return [];
}

void _documentPageDomAttach(
    IsarCollection<dynamic> col, Id id, DocumentPageDom object) {
  object.id = id;
}

extension DocumentPageDomQueryWhereSort
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QWhere> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhere> anyPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pageIndex'),
      );
    });
  }
}

extension DocumentPageDomQueryWhere
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QWhereClause> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'documentId',
        value: [documentId],
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      pageIndexEqualTo(int pageIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pageIndex',
        value: [pageIndex],
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      pageIndexNotEqualTo(int pageIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [],
              upper: [pageIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [pageIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [pageIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [],
              upper: [pageIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      pageIndexGreaterThan(
    int pageIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [pageIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      pageIndexLessThan(
    int pageIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [],
        upper: [pageIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterWhereClause>
      pageIndexBetween(
    int lowerPageIndex,
    int upperPageIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [lowerPageIndex],
        includeLower: includeLower,
        upper: [upperPageIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DocumentPageDomQueryFilter
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QFilterCondition> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'documentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'elements',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      pageIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      pageIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      pageIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      pageIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pageIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DocumentPageDomQueryObject
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QFilterCondition> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterFilterCondition>
      elementsElement(FilterQuery<DomElement> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'elements');
    });
  }
}

extension DocumentPageDomQueryLinks
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QFilterCondition> {}

extension DocumentPageDomQuerySortBy
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QSortBy> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      sortByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.asc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      sortByPageIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.desc);
    });
  }
}

extension DocumentPageDomQuerySortThenBy
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QSortThenBy> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      thenByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.asc);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QAfterSortBy>
      thenByPageIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.desc);
    });
  }
}

extension DocumentPageDomQueryWhereDistinct
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QDistinct> {
  QueryBuilder<DocumentPageDom, DocumentPageDom, QDistinct>
      distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentPageDom, DocumentPageDom, QDistinct>
      distinctByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageIndex');
    });
  }
}

extension DocumentPageDomQueryProperty
    on QueryBuilder<DocumentPageDom, DocumentPageDom, QQueryProperty> {
  QueryBuilder<DocumentPageDom, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DocumentPageDom, String, QQueryOperations> documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<DocumentPageDom, List<DomElement>, QQueryOperations>
      elementsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elements');
    });
  }

  QueryBuilder<DocumentPageDom, int, QQueryOperations> pageIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageIndex');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSemanticEmbeddingCollection on Isar {
  IsarCollection<SemanticEmbedding> get semanticEmbeddings => this.collection();
}

const SemanticEmbeddingSchema = CollectionSchema(
  name: r'SemanticEmbedding',
  id: -4260432402017748886,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'documentId': PropertySchema(
      id: 1,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'pageIndex': PropertySchema(
      id: 2,
      name: r'pageIndex',
      type: IsarType.long,
    ),
    r'vector': PropertySchema(
      id: 3,
      name: r'vector',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _semanticEmbeddingEstimateSize,
  serialize: _semanticEmbeddingSerialize,
  deserialize: _semanticEmbeddingDeserialize,
  deserializeProp: _semanticEmbeddingDeserializeProp,
  idName: r'id',
  indexes: {
    r'documentId': IndexSchema(
      id: 4187168439921340405,
      name: r'documentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'pageIndex': IndexSchema(
      id: -6792988718546572558,
      name: r'pageIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pageIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _semanticEmbeddingGetId,
  getLinks: _semanticEmbeddingGetLinks,
  attach: _semanticEmbeddingAttach,
  version: '3.1.0+1',
);

int _semanticEmbeddingEstimateSize(
  SemanticEmbedding object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.vector.length * 8;
  return bytesCount;
}

void _semanticEmbeddingSerialize(
  SemanticEmbedding object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeString(offsets[1], object.documentId);
  writer.writeLong(offsets[2], object.pageIndex);
  writer.writeDoubleList(offsets[3], object.vector);
}

SemanticEmbedding _semanticEmbeddingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SemanticEmbedding(
    content: reader.readString(offsets[0]),
    documentId: reader.readString(offsets[1]),
    pageIndex: reader.readLong(offsets[2]),
    vector: reader.readDoubleList(offsets[3]) ?? [],
  );
  object.id = id;
  return object;
}

P _semanticEmbeddingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDoubleList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _semanticEmbeddingGetId(SemanticEmbedding object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _semanticEmbeddingGetLinks(
    SemanticEmbedding object) {
  return [];
}

void _semanticEmbeddingAttach(
    IsarCollection<dynamic> col, Id id, SemanticEmbedding object) {
  object.id = id;
}

extension SemanticEmbeddingQueryWhereSort
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QWhere> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhere>
      anyPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pageIndex'),
      );
    });
  }
}

extension SemanticEmbeddingQueryWhere
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QWhereClause> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'documentId',
        value: [documentId],
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      pageIndexEqualTo(int pageIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pageIndex',
        value: [pageIndex],
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      pageIndexNotEqualTo(int pageIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [],
              upper: [pageIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [pageIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [pageIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pageIndex',
              lower: [],
              upper: [pageIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      pageIndexGreaterThan(
    int pageIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [pageIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      pageIndexLessThan(
    int pageIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [],
        upper: [pageIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterWhereClause>
      pageIndexBetween(
    int lowerPageIndex,
    int upperPageIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pageIndex',
        lower: [lowerPageIndex],
        includeLower: includeLower,
        upper: [upperPageIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SemanticEmbeddingQueryFilter
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QFilterCondition> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'documentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      pageIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      pageIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      pageIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pageIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      pageIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pageIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vector',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterFilterCondition>
      vectorLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension SemanticEmbeddingQueryObject
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QFilterCondition> {}

extension SemanticEmbeddingQueryLinks
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QFilterCondition> {}

extension SemanticEmbeddingQuerySortBy
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QSortBy> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      sortByPageIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.desc);
    });
  }
}

extension SemanticEmbeddingQuerySortThenBy
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QSortThenBy> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.asc);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QAfterSortBy>
      thenByPageIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageIndex', Sort.desc);
    });
  }
}

extension SemanticEmbeddingQueryWhereDistinct
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QDistinct> {
  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QDistinct>
      distinctByContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QDistinct>
      distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QDistinct>
      distinctByPageIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageIndex');
    });
  }

  QueryBuilder<SemanticEmbedding, SemanticEmbedding, QDistinct>
      distinctByVector() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vector');
    });
  }
}

extension SemanticEmbeddingQueryProperty
    on QueryBuilder<SemanticEmbedding, SemanticEmbedding, QQueryProperty> {
  QueryBuilder<SemanticEmbedding, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SemanticEmbedding, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<SemanticEmbedding, String, QQueryOperations>
      documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<SemanticEmbedding, int, QQueryOperations> pageIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageIndex');
    });
  }

  QueryBuilder<SemanticEmbedding, List<double>, QQueryOperations>
      vectorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vector');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DomElementSchema = Schema(
  name: r'DomElement',
  id: 8526635879648259955,
  properties: {
    r'embeddingId': PropertySchema(
      id: 0,
      name: r'embeddingId',
      type: IsarType.long,
    ),
    r'fontFamily': PropertySchema(
      id: 1,
      name: r'fontFamily',
      type: IsarType.string,
    ),
    r'fontSize': PropertySchema(
      id: 2,
      name: r'fontSize',
      type: IsarType.double,
    ),
    r'height': PropertySchema(
      id: 3,
      name: r'height',
      type: IsarType.double,
    ),
    r'left': PropertySchema(
      id: 4,
      name: r'left',
      type: IsarType.double,
    ),
    r'text': PropertySchema(
      id: 5,
      name: r'text',
      type: IsarType.string,
    ),
    r'top': PropertySchema(
      id: 6,
      name: r'top',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.byte,
      enumMap: _DomElementtypeEnumValueMap,
    ),
    r'width': PropertySchema(
      id: 8,
      name: r'width',
      type: IsarType.double,
    )
  },
  estimateSize: _domElementEstimateSize,
  serialize: _domElementSerialize,
  deserialize: _domElementDeserialize,
  deserializeProp: _domElementDeserializeProp,
);

int _domElementEstimateSize(
  DomElement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.fontFamily;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _domElementSerialize(
  DomElement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.embeddingId);
  writer.writeString(offsets[1], object.fontFamily);
  writer.writeDouble(offsets[2], object.fontSize);
  writer.writeDouble(offsets[3], object.height);
  writer.writeDouble(offsets[4], object.left);
  writer.writeString(offsets[5], object.text);
  writer.writeDouble(offsets[6], object.top);
  writer.writeByte(offsets[7], object.type.index);
  writer.writeDouble(offsets[8], object.width);
}

DomElement _domElementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DomElement(
    embeddingId: reader.readLongOrNull(offsets[0]),
    fontFamily: reader.readStringOrNull(offsets[1]),
    fontSize: reader.readDoubleOrNull(offsets[2]),
    height: reader.readDoubleOrNull(offsets[3]) ?? 0,
    left: reader.readDoubleOrNull(offsets[4]) ?? 0,
    text: reader.readStringOrNull(offsets[5]),
    top: reader.readDoubleOrNull(offsets[6]) ?? 0,
    type: _DomElementtypeValueEnumMap[reader.readByteOrNull(offsets[7])] ??
        DomElementType.paragraph,
    width: reader.readDoubleOrNull(offsets[8]) ?? 0,
  );
  return object;
}

P _domElementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 4:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 7:
      return (_DomElementtypeValueEnumMap[reader.readByteOrNull(offset)] ??
          DomElementType.paragraph) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DomElementtypeEnumValueMap = {
  'title': 0,
  'heading': 1,
  'paragraph': 2,
  'table': 3,
  'image': 4,
  'formField': 5,
  'signature': 6,
  'footnote': 7,
  'list': 8,
};
const _DomElementtypeValueEnumMap = {
  0: DomElementType.title,
  1: DomElementType.heading,
  2: DomElementType.paragraph,
  3: DomElementType.table,
  4: DomElementType.image,
  5: DomElementType.formField,
  6: DomElementType.signature,
  7: DomElementType.footnote,
  8: DomElementType.list,
};

extension DomElementQueryFilter
    on QueryBuilder<DomElement, DomElement, QFilterCondition> {
  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'embeddingId',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'embeddingId',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingId',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'embeddingId',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'embeddingId',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      embeddingIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'embeddingId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fontFamily',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fontFamily',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontFamilyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontFamilyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontFamily',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontFamilyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fontFamily',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontFamilyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fontSize',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fontSize',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontSizeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition>
      fontSizeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontSizeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> fontSizeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> heightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> heightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> heightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> heightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> leftEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> leftGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> leftLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> leftBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'left',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> topEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> topGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> topLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> topBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'top',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> typeEqualTo(
      DomElementType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> typeGreaterThan(
    DomElementType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> typeLessThan(
    DomElementType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> typeBetween(
    DomElementType lower,
    DomElementType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> widthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> widthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> widthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DomElement, DomElement, QAfterFilterCondition> widthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension DomElementQueryObject
    on QueryBuilder<DomElement, DomElement, QFilterCondition> {}
