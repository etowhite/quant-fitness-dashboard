// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetBodyMeasurementCollection on Isar {
  IsarCollection<BodyMeasurement> get bodyMeasurements => this.collection();
}

const BodyMeasurementSchema = CollectionSchema(
  name: r'BodyMeasurement',
  id: -9058319788105540477,
  properties: {
    r'biceps': PropertySchema(
      id: 0,
      name: r'biceps',
      type: IsarType.double,
    ),
    r'bodyFat': PropertySchema(
      id: 1,
      name: r'bodyFat',
      type: IsarType.double,
    ),
    r'chest': PropertySchema(
      id: 2,
      name: r'chest',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 3,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'hips': PropertySchema(
      id: 4,
      name: r'hips',
      type: IsarType.double,
    ),
    r'note': PropertySchema(
      id: 5,
      name: r'note',
      type: IsarType.string,
    ),
    r'waist': PropertySchema(
      id: 6,
      name: r'waist',
      type: IsarType.double,
    ),
    r'weight': PropertySchema(
      id: 7,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _bodyMeasurementEstimateSize,
  serialize: _bodyMeasurementSerialize,
  deserialize: _bodyMeasurementDeserialize,
  deserializeProp: _bodyMeasurementDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _bodyMeasurementGetId,
  getLinks: _bodyMeasurementGetLinks,
  attach: _bodyMeasurementAttach,
  version: '3.4.1',
);

int _bodyMeasurementEstimateSize(
  BodyMeasurement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _bodyMeasurementSerialize(
  BodyMeasurement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.biceps);
  writer.writeDouble(offsets[1], object.bodyFat);
  writer.writeDouble(offsets[2], object.chest);
  writer.writeDateTime(offsets[3], object.date);
  writer.writeDouble(offsets[4], object.hips);
  writer.writeString(offsets[5], object.note);
  writer.writeDouble(offsets[6], object.waist);
  writer.writeDouble(offsets[7], object.weight);
}

BodyMeasurement _bodyMeasurementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BodyMeasurement();
  object.biceps = reader.readDoubleOrNull(offsets[0]);
  object.bodyFat = reader.readDoubleOrNull(offsets[1]);
  object.chest = reader.readDoubleOrNull(offsets[2]);
  object.date = reader.readDateTime(offsets[3]);
  object.hips = reader.readDoubleOrNull(offsets[4]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[5]);
  object.waist = reader.readDoubleOrNull(offsets[6]);
  object.weight = reader.readDoubleOrNull(offsets[7]);
  return object;
}

P _bodyMeasurementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bodyMeasurementGetId(BodyMeasurement object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _bodyMeasurementGetLinks(BodyMeasurement object) {
  return [];
}

void _bodyMeasurementAttach(
    IsarCollection<dynamic> col, Id id, BodyMeasurement object) {
  object.id = id;
}

extension BodyMeasurementByIndex on IsarCollection<BodyMeasurement> {
  Future<BodyMeasurement?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  BodyMeasurement? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<BodyMeasurement?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<BodyMeasurement?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(BodyMeasurement object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(BodyMeasurement object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<BodyMeasurement> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<BodyMeasurement> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension BodyMeasurementQueryWhereSort
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QWhere> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension BodyMeasurementQueryWhere
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QWhereClause> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BodyMeasurementQueryFilter
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'biceps',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'biceps',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bicepsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'biceps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idGreaterThan(
    Id? value, {
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idLessThan(
    Id? value, {
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idBetween(
    Id? lower,
    Id? upper, {
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BodyMeasurementQueryObject
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {}

extension BodyMeasurementQueryLinks
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {}

extension BodyMeasurementQuerySortBy
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QSortBy> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByBicepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension BodyMeasurementQuerySortThenBy
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QSortThenBy> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByBicepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension BodyMeasurementQueryWhereDistinct
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'biceps');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFat');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chest');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hips');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waist');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension BodyMeasurementQueryProperty
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QQueryProperty> {
  QueryBuilder<BodyMeasurement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> bicepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'biceps');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> bodyFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFat');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> chestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chest');
    });
  }

  QueryBuilder<BodyMeasurement, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> hipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hips');
    });
  }

  QueryBuilder<BodyMeasurement, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> waistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waist');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
