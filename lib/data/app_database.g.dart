// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startSectionMeta = const VerificationMeta(
    'startSection',
  );
  @override
  late final GeneratedColumn<int> startSection = GeneratedColumn<int>(
    'start_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endSectionMeta = const VerificationMeta(
    'endSection',
  );
  @override
  late final GeneratedColumn<int> endSection = GeneratedColumn<int>(
    'end_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useExplicitTimesMeta = const VerificationMeta(
    'useExplicitTimes',
  );
  @override
  late final GeneratedColumn<bool> useExplicitTimes = GeneratedColumn<bool>(
    'use_explicit_times',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_explicit_times" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weeksMeta = const VerificationMeta('weeks');
  @override
  late final GeneratedColumn<String> weeks = GeneratedColumn<String>(
    'weeks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF5B8DEF),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    name,
    teacher,
    location,
    dayOfWeek,
    startSection,
    endSection,
    startTime,
    endTime,
    useExplicitTimes,
    weeks,
    colorValue,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_section')) {
      context.handle(
        _startSectionMeta,
        startSection.isAcceptableOrUnknown(
          data['start_section']!,
          _startSectionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSectionMeta);
    }
    if (data.containsKey('end_section')) {
      context.handle(
        _endSectionMeta,
        endSection.isAcceptableOrUnknown(data['end_section']!, _endSectionMeta),
      );
    } else if (isInserting) {
      context.missing(_endSectionMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('use_explicit_times')) {
      context.handle(
        _useExplicitTimesMeta,
        useExplicitTimes.isAcceptableOrUnknown(
          data['use_explicit_times']!,
          _useExplicitTimesMeta,
        ),
      );
    }
    if (data.containsKey('weeks')) {
      context.handle(
        _weeksMeta,
        weeks.isAcceptableOrUnknown(data['weeks']!, _weeksMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      semesterId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}semester_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      dayOfWeek:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}day_of_week'],
          )!,
      startSection:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}start_section'],
          )!,
      endSection:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}end_section'],
          )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      useExplicitTimes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}use_explicit_times'],
          )!,
      weeks:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}weeks'],
          )!,
      colorValue:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}color_value'],
          )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  final String id;
  final String semesterId;
  final String name;
  final String? teacher;
  final String? location;

  /// 1=周一 .. 7=周日，与 [DateTime.weekday] 一致。
  final int dayOfWeek;
  final int startSection;
  final int endSection;

  /// "08:00" 原始钟点，仅 [useExplicitTimes] 为 true 时参与求值。
  final String? startTime;
  final String? endTime;
  final bool useExplicitTimes;

  /// 上课周次 CSV，如 "1,2,3,16"。空串表示未设置。
  final String weeks;

  /// 卡片主题色（ARGB int）。
  final int colorValue;
  final String? notes;
  const Course({
    required this.id,
    required this.semesterId,
    required this.name,
    this.teacher,
    this.location,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    this.startTime,
    this.endTime,
    required this.useExplicitTimes,
    required this.weeks,
    required this.colorValue,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_section'] = Variable<int>(startSection);
    map['end_section'] = Variable<int>(endSection);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['use_explicit_times'] = Variable<bool>(useExplicitTimes);
    map['weeks'] = Variable<String>(weeks);
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      name: Value(name),
      teacher:
          teacher == null && nullToAbsent
              ? const Value.absent()
              : Value(teacher),
      location:
          location == null && nullToAbsent
              ? const Value.absent()
              : Value(location),
      dayOfWeek: Value(dayOfWeek),
      startSection: Value(startSection),
      endSection: Value(endSection),
      startTime:
          startTime == null && nullToAbsent
              ? const Value.absent()
              : Value(startTime),
      endTime:
          endTime == null && nullToAbsent
              ? const Value.absent()
              : Value(endTime),
      useExplicitTimes: Value(useExplicitTimes),
      weeks: Value(weeks),
      colorValue: Value(colorValue),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<String>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      name: serializer.fromJson<String>(json['name']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      location: serializer.fromJson<String?>(json['location']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startSection: serializer.fromJson<int>(json['startSection']),
      endSection: serializer.fromJson<int>(json['endSection']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      useExplicitTimes: serializer.fromJson<bool>(json['useExplicitTimes']),
      weeks: serializer.fromJson<String>(json['weeks']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'name': serializer.toJson<String>(name),
      'teacher': serializer.toJson<String?>(teacher),
      'location': serializer.toJson<String?>(location),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startSection': serializer.toJson<int>(startSection),
      'endSection': serializer.toJson<int>(endSection),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'useExplicitTimes': serializer.toJson<bool>(useExplicitTimes),
      'weeks': serializer.toJson<String>(weeks),
      'colorValue': serializer.toJson<int>(colorValue),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Course copyWith({
    String? id,
    String? semesterId,
    String? name,
    Value<String?> teacher = const Value.absent(),
    Value<String?> location = const Value.absent(),
    int? dayOfWeek,
    int? startSection,
    int? endSection,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    bool? useExplicitTimes,
    String? weeks,
    int? colorValue,
    Value<String?> notes = const Value.absent(),
  }) => Course(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    name: name ?? this.name,
    teacher: teacher.present ? teacher.value : this.teacher,
    location: location.present ? location.value : this.location,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    useExplicitTimes: useExplicitTimes ?? this.useExplicitTimes,
    weeks: weeks ?? this.weeks,
    colorValue: colorValue ?? this.colorValue,
    notes: notes.present ? notes.value : this.notes,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      name: data.name.present ? data.name.value : this.name,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      location: data.location.present ? data.location.value : this.location,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startSection:
          data.startSection.present
              ? data.startSection.value
              : this.startSection,
      endSection:
          data.endSection.present ? data.endSection.value : this.endSection,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      useExplicitTimes:
          data.useExplicitTimes.present
              ? data.useExplicitTimes.value
              : this.useExplicitTimes,
      weeks: data.weeks.present ? data.weeks.value : this.weeks,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('location: $location, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('useExplicitTimes: $useExplicitTimes, ')
          ..write('weeks: $weeks, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    name,
    teacher,
    location,
    dayOfWeek,
    startSection,
    endSection,
    startTime,
    endTime,
    useExplicitTimes,
    weeks,
    colorValue,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.name == this.name &&
          other.teacher == this.teacher &&
          other.location == this.location &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startSection == this.startSection &&
          other.endSection == this.endSection &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.useExplicitTimes == this.useExplicitTimes &&
          other.weeks == this.weeks &&
          other.colorValue == this.colorValue &&
          other.notes == this.notes);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<String> id;
  final Value<String> semesterId;
  final Value<String> name;
  final Value<String?> teacher;
  final Value<String?> location;
  final Value<int> dayOfWeek;
  final Value<int> startSection;
  final Value<int> endSection;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<bool> useExplicitTimes;
  final Value<String> weeks;
  final Value<int> colorValue;
  final Value<String?> notes;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.name = const Value.absent(),
    this.teacher = const Value.absent(),
    this.location = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startSection = const Value.absent(),
    this.endSection = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.useExplicitTimes = const Value.absent(),
    this.weeks = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String semesterId,
    required String name,
    this.teacher = const Value.absent(),
    this.location = const Value.absent(),
    required int dayOfWeek,
    required int startSection,
    required int endSection,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.useExplicitTimes = const Value.absent(),
    this.weeks = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       semesterId = Value(semesterId),
       name = Value(name),
       dayOfWeek = Value(dayOfWeek),
       startSection = Value(startSection),
       endSection = Value(endSection);
  static Insertable<Course> custom({
    Expression<String>? id,
    Expression<String>? semesterId,
    Expression<String>? name,
    Expression<String>? teacher,
    Expression<String>? location,
    Expression<int>? dayOfWeek,
    Expression<int>? startSection,
    Expression<int>? endSection,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<bool>? useExplicitTimes,
    Expression<String>? weeks,
    Expression<int>? colorValue,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (name != null) 'name': name,
      if (teacher != null) 'teacher': teacher,
      if (location != null) 'location': location,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startSection != null) 'start_section': startSection,
      if (endSection != null) 'end_section': endSection,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (useExplicitTimes != null) 'use_explicit_times': useExplicitTimes,
      if (weeks != null) 'weeks': weeks,
      if (colorValue != null) 'color_value': colorValue,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? semesterId,
    Value<String>? name,
    Value<String?>? teacher,
    Value<String?>? location,
    Value<int>? dayOfWeek,
    Value<int>? startSection,
    Value<int>? endSection,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<bool>? useExplicitTimes,
    Value<String>? weeks,
    Value<int>? colorValue,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      useExplicitTimes: useExplicitTimes ?? this.useExplicitTimes,
      weeks: weeks ?? this.weeks,
      colorValue: colorValue ?? this.colorValue,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startSection.present) {
      map['start_section'] = Variable<int>(startSection.value);
    }
    if (endSection.present) {
      map['end_section'] = Variable<int>(endSection.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (useExplicitTimes.present) {
      map['use_explicit_times'] = Variable<bool>(useExplicitTimes.value);
    }
    if (weeks.present) {
      map['weeks'] = Variable<String>(weeks.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('location: $location, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('useExplicitTimes: $useExplicitTimes, ')
          ..write('weeks: $weeks, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, Semester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentWeekOverrideMeta =
      const VerificationMeta('currentWeekOverride');
  @override
  late final GeneratedColumn<int> currentWeekOverride = GeneratedColumn<int>(
    'current_week_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    totalWeeks,
    currentWeekOverride,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Semester> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    } else if (isInserting) {
      context.missing(_totalWeeksMeta);
    }
    if (data.containsKey('current_week_override')) {
      context.handle(
        _currentWeekOverrideMeta,
        currentWeekOverride.isAcceptableOrUnknown(
          data['current_week_override']!,
          _currentWeekOverrideMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Semester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Semester(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      startDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}start_date'],
          )!,
      totalWeeks:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_weeks'],
          )!,
      currentWeekOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_week_override'],
      ),
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class Semester extends DataClass implements Insertable<Semester> {
  final String id;
  final String name;

  /// 开学第一天（日期，忽略时间部分）。
  final DateTime startDate;
  final int totalWeeks;

  /// 手动覆盖的当前周（调课/假期）。null 表示按开学日期自动推算。
  final int? currentWeekOverride;

  /// 是否当前激活学期（同一时刻至多一个为 true）。
  final bool isActive;
  const Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalWeeks,
    this.currentWeekOverride,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<DateTime>(startDate);
    map['total_weeks'] = Variable<int>(totalWeeks);
    if (!nullToAbsent || currentWeekOverride != null) {
      map['current_week_override'] = Variable<int>(currentWeekOverride);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      totalWeeks: Value(totalWeeks),
      currentWeekOverride:
          currentWeekOverride == null && nullToAbsent
              ? const Value.absent()
              : Value(currentWeekOverride),
      isActive: Value(isActive),
    );
  }

  factory Semester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Semester(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      totalWeeks: serializer.fromJson<int>(json['totalWeeks']),
      currentWeekOverride: serializer.fromJson<int?>(
        json['currentWeekOverride'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<DateTime>(startDate),
      'totalWeeks': serializer.toJson<int>(totalWeeks),
      'currentWeekOverride': serializer.toJson<int?>(currentWeekOverride),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Semester copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    Value<int?> currentWeekOverride = const Value.absent(),
    bool? isActive,
  }) => Semester(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    totalWeeks: totalWeeks ?? this.totalWeeks,
    currentWeekOverride:
        currentWeekOverride.present
            ? currentWeekOverride.value
            : this.currentWeekOverride,
    isActive: isActive ?? this.isActive,
  );
  Semester copyWithCompanion(SemestersCompanion data) {
    return Semester(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      totalWeeks:
          data.totalWeeks.present ? data.totalWeeks.value : this.totalWeeks,
      currentWeekOverride:
          data.currentWeekOverride.present
              ? data.currentWeekOverride.value
              : this.currentWeekOverride,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Semester(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('currentWeekOverride: $currentWeekOverride, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    totalWeeks,
    currentWeekOverride,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.totalWeeks == this.totalWeeks &&
          other.currentWeekOverride == this.currentWeekOverride &&
          other.isActive == this.isActive);
}

class SemestersCompanion extends UpdateCompanion<Semester> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startDate;
  final Value<int> totalWeeks;
  final Value<int?> currentWeekOverride;
  final Value<bool> isActive;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.currentWeekOverride = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String name,
    required DateTime startDate,
    required int totalWeeks,
    this.currentWeekOverride = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate),
       totalWeeks = Value(totalWeeks);
  static Insertable<Semester> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startDate,
    Expression<int>? totalWeeks,
    Expression<int>? currentWeekOverride,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (currentWeekOverride != null)
        'current_week_override': currentWeekOverride,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? startDate,
    Value<int>? totalWeeks,
    Value<int?>? currentWeekOverride,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      currentWeekOverride: currentWeekOverride ?? this.currentWeekOverride,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (currentWeekOverride.present) {
      map['current_week_override'] = Variable<int>(currentWeekOverride.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('currentWeekOverride: $currentWeekOverride, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursePlatformsTable extends CoursePlatforms
    with TableInfo<$CoursePlatformsTable, CoursePlatform> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursePlatformsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    courseName,
    purpose,
    name,
    url,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_platforms';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoursePlatform> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoursePlatform map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoursePlatform(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      semesterId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}semester_id'],
          )!,
      courseName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_name'],
          )!,
      purpose:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}purpose'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $CoursePlatformsTable createAlias(String alias) {
    return $CoursePlatformsTable(attachedDatabase, alias);
  }
}

class CoursePlatform extends DataClass implements Insertable<CoursePlatform> {
  final int id;
  final String semesterId;
  final String courseName;

  /// 用途的稳定键，见 `CoursePlatformPurpose.key`。
  final String purpose;
  final String name;
  final String? url;
  final int sortOrder;
  const CoursePlatform({
    required this.id,
    required this.semesterId,
    required this.courseName,
    required this.purpose,
    required this.name,
    this.url,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['course_name'] = Variable<String>(courseName);
    map['purpose'] = Variable<String>(purpose);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CoursePlatformsCompanion toCompanion(bool nullToAbsent) {
    return CoursePlatformsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      courseName: Value(courseName),
      purpose: Value(purpose),
      name: Value(name),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      sortOrder: Value(sortOrder),
    );
  }

  factory CoursePlatform.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoursePlatform(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      courseName: serializer.fromJson<String>(json['courseName']),
      purpose: serializer.fromJson<String>(json['purpose']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String?>(json['url']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'courseName': serializer.toJson<String>(courseName),
      'purpose': serializer.toJson<String>(purpose),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String?>(url),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CoursePlatform copyWith({
    int? id,
    String? semesterId,
    String? courseName,
    String? purpose,
    String? name,
    Value<String?> url = const Value.absent(),
    int? sortOrder,
  }) => CoursePlatform(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    courseName: courseName ?? this.courseName,
    purpose: purpose ?? this.purpose,
    name: name ?? this.name,
    url: url.present ? url.value : this.url,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CoursePlatform copyWithCompanion(CoursePlatformsCompanion data) {
    return CoursePlatform(
      id: data.id.present ? data.id.value : this.id,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      courseName:
          data.courseName.present ? data.courseName.value : this.courseName,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoursePlatform(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseName: $courseName, ')
          ..write('purpose: $purpose, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, semesterId, courseName, purpose, name, url, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoursePlatform &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.courseName == this.courseName &&
          other.purpose == this.purpose &&
          other.name == this.name &&
          other.url == this.url &&
          other.sortOrder == this.sortOrder);
}

class CoursePlatformsCompanion extends UpdateCompanion<CoursePlatform> {
  final Value<int> id;
  final Value<String> semesterId;
  final Value<String> courseName;
  final Value<String> purpose;
  final Value<String> name;
  final Value<String?> url;
  final Value<int> sortOrder;
  const CoursePlatformsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.courseName = const Value.absent(),
    this.purpose = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CoursePlatformsCompanion.insert({
    this.id = const Value.absent(),
    required String semesterId,
    required String courseName,
    required String purpose,
    required String name,
    this.url = const Value.absent(),
    required int sortOrder,
  }) : semesterId = Value(semesterId),
       courseName = Value(courseName),
       purpose = Value(purpose),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<CoursePlatform> custom({
    Expression<int>? id,
    Expression<String>? semesterId,
    Expression<String>? courseName,
    Expression<String>? purpose,
    Expression<String>? name,
    Expression<String>? url,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (courseName != null) 'course_name': courseName,
      if (purpose != null) 'purpose': purpose,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CoursePlatformsCompanion copyWith({
    Value<int>? id,
    Value<String>? semesterId,
    Value<String>? courseName,
    Value<String>? purpose,
    Value<String>? name,
    Value<String?>? url,
    Value<int>? sortOrder,
  }) {
    return CoursePlatformsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      courseName: courseName ?? this.courseName,
      purpose: purpose ?? this.purpose,
      name: name ?? this.name,
      url: url ?? this.url,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursePlatformsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseName: $courseName, ')
          ..write('purpose: $purpose, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CoursePlatformsTable coursePlatforms = $CoursePlatformsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    courses,
    semesters,
    coursePlatforms,
  ];
}

typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      required String id,
      required String semesterId,
      required String name,
      Value<String?> teacher,
      Value<String?> location,
      required int dayOfWeek,
      required int startSection,
      required int endSection,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<bool> useExplicitTimes,
      Value<String> weeks,
      Value<int> colorValue,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<String> semesterId,
      Value<String> name,
      Value<String?> teacher,
      Value<String?> location,
      Value<int> dayOfWeek,
      Value<int> startSection,
      Value<int> endSection,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<bool> useExplicitTimes,
      Value<String> weeks,
      Value<int> colorValue,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useExplicitTimes => $composableBuilder(
    column: $table.useExplicitTimes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useExplicitTimes => $composableBuilder(
    column: $table.useExplicitTimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get useExplicitTimes => $composableBuilder(
    column: $table.useExplicitTimes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weeks =>
      $composableBuilder(column: $table.weeks, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, BaseReferences<_$AppDatabase, $CoursesTable, Course>),
          Course,
          PrefetchHooks Function()
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> startSection = const Value.absent(),
                Value<int> endSection = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<bool> useExplicitTimes = const Value.absent(),
                Value<String> weeks = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                semesterId: semesterId,
                name: name,
                teacher: teacher,
                location: location,
                dayOfWeek: dayOfWeek,
                startSection: startSection,
                endSection: endSection,
                startTime: startTime,
                endTime: endTime,
                useExplicitTimes: useExplicitTimes,
                weeks: weeks,
                colorValue: colorValue,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String semesterId,
                required String name,
                Value<String?> teacher = const Value.absent(),
                Value<String?> location = const Value.absent(),
                required int dayOfWeek,
                required int startSection,
                required int endSection,
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<bool> useExplicitTimes = const Value.absent(),
                Value<String> weeks = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                semesterId: semesterId,
                name: name,
                teacher: teacher,
                location: location,
                dayOfWeek: dayOfWeek,
                startSection: startSection,
                endSection: endSection,
                startTime: startTime,
                endTime: endTime,
                useExplicitTimes: useExplicitTimes,
                weeks: weeks,
                colorValue: colorValue,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, BaseReferences<_$AppDatabase, $CoursesTable, Course>),
      Course,
      PrefetchHooks Function()
    >;
typedef $$SemestersTableCreateCompanionBuilder =
    SemestersCompanion Function({
      required String id,
      required String name,
      required DateTime startDate,
      required int totalWeeks,
      Value<int?> currentWeekOverride,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$SemestersTableUpdateCompanionBuilder =
    SemestersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> startDate,
      Value<int> totalWeeks,
      Value<int?> currentWeekOverride,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentWeekOverride => $composableBuilder(
    column: $table.currentWeekOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentWeekOverride => $composableBuilder(
    column: $table.currentWeekOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentWeekOverride => $composableBuilder(
    column: $table.currentWeekOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          Semester,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (Semester, BaseReferences<_$AppDatabase, $SemestersTable, Semester>),
          Semester,
          PrefetchHooks Function()
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> totalWeeks = const Value.absent(),
                Value<int?> currentWeekOverride = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion(
                id: id,
                name: name,
                startDate: startDate,
                totalWeeks: totalWeeks,
                currentWeekOverride: currentWeekOverride,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime startDate,
                required int totalWeeks,
                Value<int?> currentWeekOverride = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                totalWeeks: totalWeeks,
                currentWeekOverride: currentWeekOverride,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      Semester,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (Semester, BaseReferences<_$AppDatabase, $SemestersTable, Semester>),
      Semester,
      PrefetchHooks Function()
    >;
typedef $$CoursePlatformsTableCreateCompanionBuilder =
    CoursePlatformsCompanion Function({
      Value<int> id,
      required String semesterId,
      required String courseName,
      required String purpose,
      required String name,
      Value<String?> url,
      required int sortOrder,
    });
typedef $$CoursePlatformsTableUpdateCompanionBuilder =
    CoursePlatformsCompanion Function({
      Value<int> id,
      Value<String> semesterId,
      Value<String> courseName,
      Value<String> purpose,
      Value<String> name,
      Value<String?> url,
      Value<int> sortOrder,
    });

class $$CoursePlatformsTableFilterComposer
    extends Composer<_$AppDatabase, $CoursePlatformsTable> {
  $$CoursePlatformsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoursePlatformsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursePlatformsTable> {
  $$CoursePlatformsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursePlatformsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursePlatformsTable> {
  $$CoursePlatformsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CoursePlatformsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursePlatformsTable,
          CoursePlatform,
          $$CoursePlatformsTableFilterComposer,
          $$CoursePlatformsTableOrderingComposer,
          $$CoursePlatformsTableAnnotationComposer,
          $$CoursePlatformsTableCreateCompanionBuilder,
          $$CoursePlatformsTableUpdateCompanionBuilder,
          (
            CoursePlatform,
            BaseReferences<
              _$AppDatabase,
              $CoursePlatformsTable,
              CoursePlatform
            >,
          ),
          CoursePlatform,
          PrefetchHooks Function()
        > {
  $$CoursePlatformsTableTableManager(
    _$AppDatabase db,
    $CoursePlatformsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CoursePlatformsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CoursePlatformsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CoursePlatformsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CoursePlatformsCompanion(
                id: id,
                semesterId: semesterId,
                courseName: courseName,
                purpose: purpose,
                name: name,
                url: url,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String semesterId,
                required String courseName,
                required String purpose,
                required String name,
                Value<String?> url = const Value.absent(),
                required int sortOrder,
              }) => CoursePlatformsCompanion.insert(
                id: id,
                semesterId: semesterId,
                courseName: courseName,
                purpose: purpose,
                name: name,
                url: url,
                sortOrder: sortOrder,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoursePlatformsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursePlatformsTable,
      CoursePlatform,
      $$CoursePlatformsTableFilterComposer,
      $$CoursePlatformsTableOrderingComposer,
      $$CoursePlatformsTableAnnotationComposer,
      $$CoursePlatformsTableCreateCompanionBuilder,
      $$CoursePlatformsTableUpdateCompanionBuilder,
      (
        CoursePlatform,
        BaseReferences<_$AppDatabase, $CoursePlatformsTable, CoursePlatform>,
      ),
      CoursePlatform,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CoursePlatformsTableTableManager get coursePlatforms =>
      $$CoursePlatformsTableTableManager(_db, _db.coursePlatforms);
}
