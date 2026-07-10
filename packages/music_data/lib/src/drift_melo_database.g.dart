// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_melo_database.dart';

// ignore_for_file: type=lint
class $MeloMetaRowsTable extends MeloMetaRows
    with TableInfo<$MeloMetaRowsTable, MeloMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeloMetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'melo_meta_rows';
  @override
  VerificationContext validateIntegrity(Insertable<MeloMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MeloMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeloMetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $MeloMetaRowsTable createAlias(String alias) {
    return $MeloMetaRowsTable(attachedDatabase, alias);
  }
}

class MeloMetaRow extends DataClass implements Insertable<MeloMetaRow> {
  final String key;
  final String value;
  const MeloMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MeloMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return MeloMetaRowsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory MeloMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeloMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MeloMetaRow copyWith({String? key, String? value}) => MeloMetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  MeloMetaRow copyWithCompanion(MeloMetaRowsCompanion data) {
    return MeloMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeloMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeloMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class MeloMetaRowsCompanion extends UpdateCompanion<MeloMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MeloMetaRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeloMetaRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<MeloMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeloMetaRowsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return MeloMetaRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeloMetaRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredPlaylistsTable extends StoredPlaylists
    with TableInfo<$StoredPlaylistsTable, StoredPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, sortIndex, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<StoredPlaylist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPlaylist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
    );
  }

  @override
  $StoredPlaylistsTable createAlias(String alias) {
    return $StoredPlaylistsTable(attachedDatabase, alias);
  }
}

class StoredPlaylist extends DataClass implements Insertable<StoredPlaylist> {
  final String id;
  final int sortIndex;
  final String payloadJson;
  const StoredPlaylist(
      {required this.id, required this.sortIndex, required this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sort_index'] = Variable<int>(sortIndex);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  StoredPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return StoredPlaylistsCompanion(
      id: Value(id),
      sortIndex: Value(sortIndex),
      payloadJson: Value(payloadJson),
    );
  }

  factory StoredPlaylist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPlaylist(
      id: serializer.fromJson<String>(json['id']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  StoredPlaylist copyWith({String? id, int? sortIndex, String? payloadJson}) =>
      StoredPlaylist(
        id: id ?? this.id,
        sortIndex: sortIndex ?? this.sortIndex,
        payloadJson: payloadJson ?? this.payloadJson,
      );
  StoredPlaylist copyWithCompanion(StoredPlaylistsCompanion data) {
    return StoredPlaylist(
      id: data.id.present ? data.id.value : this.id,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylist(')
          ..write('id: $id, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sortIndex, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPlaylist &&
          other.id == this.id &&
          other.sortIndex == this.sortIndex &&
          other.payloadJson == this.payloadJson);
}

class StoredPlaylistsCompanion extends UpdateCompanion<StoredPlaylist> {
  final Value<String> id;
  final Value<int> sortIndex;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const StoredPlaylistsCompanion({
    this.id = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredPlaylistsCompanion.insert({
    required String id,
    required int sortIndex,
    required String payloadJson,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sortIndex = Value(sortIndex),
        payloadJson = Value(payloadJson);
  static Insertable<StoredPlaylist> custom({
    Expression<String>? id,
    Expression<int>? sortIndex,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredPlaylistsCompanion copyWith(
      {Value<String>? id,
      Value<int>? sortIndex,
      Value<String>? payloadJson,
      Value<int>? rowid}) {
    return StoredPlaylistsCompanion(
      id: id ?? this.id,
      sortIndex: sortIndex ?? this.sortIndex,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredDownloadTasksTable extends StoredDownloadTasks
    with TableInfo<$StoredDownloadTasksTable, StoredDownloadTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredDownloadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _refKeyMeta = const VerificationMeta('refKey');
  @override
  late final GeneratedColumn<String> refKey = GeneratedColumn<String>(
      'ref_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [refKey, sortIndex, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_download_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<StoredDownloadTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ref_key')) {
      context.handle(_refKeyMeta,
          refKey.isAcceptableOrUnknown(data['ref_key']!, _refKeyMeta));
    } else if (isInserting) {
      context.missing(_refKeyMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {refKey};
  @override
  StoredDownloadTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredDownloadTask(
      refKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_key'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
    );
  }

  @override
  $StoredDownloadTasksTable createAlias(String alias) {
    return $StoredDownloadTasksTable(attachedDatabase, alias);
  }
}

class StoredDownloadTask extends DataClass
    implements Insertable<StoredDownloadTask> {
  final String refKey;
  final int sortIndex;
  final String payloadJson;
  const StoredDownloadTask(
      {required this.refKey,
      required this.sortIndex,
      required this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ref_key'] = Variable<String>(refKey);
    map['sort_index'] = Variable<int>(sortIndex);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  StoredDownloadTasksCompanion toCompanion(bool nullToAbsent) {
    return StoredDownloadTasksCompanion(
      refKey: Value(refKey),
      sortIndex: Value(sortIndex),
      payloadJson: Value(payloadJson),
    );
  }

  factory StoredDownloadTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredDownloadTask(
      refKey: serializer.fromJson<String>(json['refKey']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'refKey': serializer.toJson<String>(refKey),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  StoredDownloadTask copyWith(
          {String? refKey, int? sortIndex, String? payloadJson}) =>
      StoredDownloadTask(
        refKey: refKey ?? this.refKey,
        sortIndex: sortIndex ?? this.sortIndex,
        payloadJson: payloadJson ?? this.payloadJson,
      );
  StoredDownloadTask copyWithCompanion(StoredDownloadTasksCompanion data) {
    return StoredDownloadTask(
      refKey: data.refKey.present ? data.refKey.value : this.refKey,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredDownloadTask(')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(refKey, sortIndex, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredDownloadTask &&
          other.refKey == this.refKey &&
          other.sortIndex == this.sortIndex &&
          other.payloadJson == this.payloadJson);
}

class StoredDownloadTasksCompanion extends UpdateCompanion<StoredDownloadTask> {
  final Value<String> refKey;
  final Value<int> sortIndex;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const StoredDownloadTasksCompanion({
    this.refKey = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredDownloadTasksCompanion.insert({
    required String refKey,
    required int sortIndex,
    required String payloadJson,
    this.rowid = const Value.absent(),
  })  : refKey = Value(refKey),
        sortIndex = Value(sortIndex),
        payloadJson = Value(payloadJson);
  static Insertable<StoredDownloadTask> custom({
    Expression<String>? refKey,
    Expression<int>? sortIndex,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (refKey != null) 'ref_key': refKey,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredDownloadTasksCompanion copyWith(
      {Value<String>? refKey,
      Value<int>? sortIndex,
      Value<String>? payloadJson,
      Value<int>? rowid}) {
    return StoredDownloadTasksCompanion(
      refKey: refKey ?? this.refKey,
      sortIndex: sortIndex ?? this.sortIndex,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (refKey.present) {
      map['ref_key'] = Variable<String>(refKey.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredDownloadTasksCompanion(')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredLocalMediaItemsTable extends StoredLocalMediaItems
    with TableInfo<$StoredLocalMediaItemsTable, StoredLocalMediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalMediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _refKeyMeta = const VerificationMeta('refKey');
  @override
  late final GeneratedColumn<String> refKey = GeneratedColumn<String>(
      'ref_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [refKey, sortIndex, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_media_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalMediaItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ref_key')) {
      context.handle(_refKeyMeta,
          refKey.isAcceptableOrUnknown(data['ref_key']!, _refKeyMeta));
    } else if (isInserting) {
      context.missing(_refKeyMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {refKey};
  @override
  StoredLocalMediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalMediaItem(
      refKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_key'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
    );
  }

  @override
  $StoredLocalMediaItemsTable createAlias(String alias) {
    return $StoredLocalMediaItemsTable(attachedDatabase, alias);
  }
}

class StoredLocalMediaItem extends DataClass
    implements Insertable<StoredLocalMediaItem> {
  final String refKey;
  final int sortIndex;
  final String payloadJson;
  const StoredLocalMediaItem(
      {required this.refKey,
      required this.sortIndex,
      required this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ref_key'] = Variable<String>(refKey);
    map['sort_index'] = Variable<int>(sortIndex);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  StoredLocalMediaItemsCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalMediaItemsCompanion(
      refKey: Value(refKey),
      sortIndex: Value(sortIndex),
      payloadJson: Value(payloadJson),
    );
  }

  factory StoredLocalMediaItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalMediaItem(
      refKey: serializer.fromJson<String>(json['refKey']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'refKey': serializer.toJson<String>(refKey),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  StoredLocalMediaItem copyWith(
          {String? refKey, int? sortIndex, String? payloadJson}) =>
      StoredLocalMediaItem(
        refKey: refKey ?? this.refKey,
        sortIndex: sortIndex ?? this.sortIndex,
        payloadJson: payloadJson ?? this.payloadJson,
      );
  StoredLocalMediaItem copyWithCompanion(StoredLocalMediaItemsCompanion data) {
    return StoredLocalMediaItem(
      refKey: data.refKey.present ? data.refKey.value : this.refKey,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalMediaItem(')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(refKey, sortIndex, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalMediaItem &&
          other.refKey == this.refKey &&
          other.sortIndex == this.sortIndex &&
          other.payloadJson == this.payloadJson);
}

class StoredLocalMediaItemsCompanion
    extends UpdateCompanion<StoredLocalMediaItem> {
  final Value<String> refKey;
  final Value<int> sortIndex;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const StoredLocalMediaItemsCompanion({
    this.refKey = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalMediaItemsCompanion.insert({
    required String refKey,
    required int sortIndex,
    required String payloadJson,
    this.rowid = const Value.absent(),
  })  : refKey = Value(refKey),
        sortIndex = Value(sortIndex),
        payloadJson = Value(payloadJson);
  static Insertable<StoredLocalMediaItem> custom({
    Expression<String>? refKey,
    Expression<int>? sortIndex,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (refKey != null) 'ref_key': refKey,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalMediaItemsCompanion copyWith(
      {Value<String>? refKey,
      Value<int>? sortIndex,
      Value<String>? payloadJson,
      Value<int>? rowid}) {
    return StoredLocalMediaItemsCompanion(
      refKey: refKey ?? this.refKey,
      sortIndex: sortIndex ?? this.sortIndex,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (refKey.present) {
      map['ref_key'] = Variable<String>(refKey.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalMediaItemsCompanion(')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredFavoriteOverridesTable extends StoredFavoriteOverrides
    with TableInfo<$StoredFavoriteOverridesTable, StoredFavoriteOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredFavoriteOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, kind, sortIndex, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_favorite_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredFavoriteOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredFavoriteOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredFavoriteOverride(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
    );
  }

  @override
  $StoredFavoriteOverridesTable createAlias(String alias) {
    return $StoredFavoriteOverridesTable(attachedDatabase, alias);
  }
}

class StoredFavoriteOverride extends DataClass
    implements Insertable<StoredFavoriteOverride> {
  final String id;
  final String kind;
  final int sortIndex;
  final String payloadJson;
  const StoredFavoriteOverride(
      {required this.id,
      required this.kind,
      required this.sortIndex,
      required this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['sort_index'] = Variable<int>(sortIndex);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  StoredFavoriteOverridesCompanion toCompanion(bool nullToAbsent) {
    return StoredFavoriteOverridesCompanion(
      id: Value(id),
      kind: Value(kind),
      sortIndex: Value(sortIndex),
      payloadJson: Value(payloadJson),
    );
  }

  factory StoredFavoriteOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredFavoriteOverride(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  StoredFavoriteOverride copyWith(
          {String? id, String? kind, int? sortIndex, String? payloadJson}) =>
      StoredFavoriteOverride(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        sortIndex: sortIndex ?? this.sortIndex,
        payloadJson: payloadJson ?? this.payloadJson,
      );
  StoredFavoriteOverride copyWithCompanion(
      StoredFavoriteOverridesCompanion data) {
    return StoredFavoriteOverride(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredFavoriteOverride(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, sortIndex, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredFavoriteOverride &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.sortIndex == this.sortIndex &&
          other.payloadJson == this.payloadJson);
}

class StoredFavoriteOverridesCompanion
    extends UpdateCompanion<StoredFavoriteOverride> {
  final Value<String> id;
  final Value<String> kind;
  final Value<int> sortIndex;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const StoredFavoriteOverridesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredFavoriteOverridesCompanion.insert({
    required String id,
    required String kind,
    required int sortIndex,
    required String payloadJson,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        sortIndex = Value(sortIndex),
        payloadJson = Value(payloadJson);
  static Insertable<StoredFavoriteOverride> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? sortIndex,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredFavoriteOverridesCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<int>? sortIndex,
      Value<String>? payloadJson,
      Value<int>? rowid}) {
    return StoredFavoriteOverridesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      sortIndex: sortIndex ?? this.sortIndex,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredFavoriteOverridesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteProviderTracksTable extends FavoriteProviderTracks
    with TableInfo<$FavoriteProviderTracksTable, FavoriteProviderTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteProviderTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refKeyMeta = const VerificationMeta('refKey');
  @override
  late final GeneratedColumn<String> refKey = GeneratedColumn<String>(
      'ref_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawLikedAtMeta =
      const VerificationMeta('rawLikedAt');
  @override
  late final GeneratedColumn<DateTime> rawLikedAt = GeneratedColumn<DateTime>(
      'raw_liked_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _likedAtSourceMeta =
      const VerificationMeta('likedAtSource');
  @override
  late final GeneratedColumn<String> likedAtSource = GeneratedColumn<String>(
      'liked_at_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _likedAtPrecisionMeta =
      const VerificationMeta('likedAtPrecision');
  @override
  late final GeneratedColumn<String> likedAtPrecision = GeneratedColumn<String>(
      'liked_at_precision', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        providerId,
        refKey,
        sortIndex,
        payloadJson,
        rawLikedAt,
        likedAtSource,
        likedAtPrecision,
        fetchedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_provider_tracks';
  @override
  VerificationContext validateIntegrity(
      Insertable<FavoriteProviderTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('ref_key')) {
      context.handle(_refKeyMeta,
          refKey.isAcceptableOrUnknown(data['ref_key']!, _refKeyMeta));
    } else if (isInserting) {
      context.missing(_refKeyMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('raw_liked_at')) {
      context.handle(
          _rawLikedAtMeta,
          rawLikedAt.isAcceptableOrUnknown(
              data['raw_liked_at']!, _rawLikedAtMeta));
    }
    if (data.containsKey('liked_at_source')) {
      context.handle(
          _likedAtSourceMeta,
          likedAtSource.isAcceptableOrUnknown(
              data['liked_at_source']!, _likedAtSourceMeta));
    }
    if (data.containsKey('liked_at_precision')) {
      context.handle(
          _likedAtPrecisionMeta,
          likedAtPrecision.isAcceptableOrUnknown(
              data['liked_at_precision']!, _likedAtPrecisionMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, refKey};
  @override
  FavoriteProviderTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteProviderTrack(
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      refKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_key'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      rawLikedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}raw_liked_at']),
      likedAtSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}liked_at_source']),
      likedAtPrecision: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}liked_at_precision']),
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $FavoriteProviderTracksTable createAlias(String alias) {
    return $FavoriteProviderTracksTable(attachedDatabase, alias);
  }
}

class FavoriteProviderTrack extends DataClass
    implements Insertable<FavoriteProviderTrack> {
  final String providerId;
  final String refKey;
  final int sortIndex;
  final String payloadJson;
  final DateTime? rawLikedAt;
  final String? likedAtSource;
  final String? likedAtPrecision;
  final DateTime fetchedAt;
  const FavoriteProviderTrack(
      {required this.providerId,
      required this.refKey,
      required this.sortIndex,
      required this.payloadJson,
      this.rawLikedAt,
      this.likedAtSource,
      this.likedAtPrecision,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['ref_key'] = Variable<String>(refKey);
    map['sort_index'] = Variable<int>(sortIndex);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || rawLikedAt != null) {
      map['raw_liked_at'] = Variable<DateTime>(rawLikedAt);
    }
    if (!nullToAbsent || likedAtSource != null) {
      map['liked_at_source'] = Variable<String>(likedAtSource);
    }
    if (!nullToAbsent || likedAtPrecision != null) {
      map['liked_at_precision'] = Variable<String>(likedAtPrecision);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  FavoriteProviderTracksCompanion toCompanion(bool nullToAbsent) {
    return FavoriteProviderTracksCompanion(
      providerId: Value(providerId),
      refKey: Value(refKey),
      sortIndex: Value(sortIndex),
      payloadJson: Value(payloadJson),
      rawLikedAt: rawLikedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rawLikedAt),
      likedAtSource: likedAtSource == null && nullToAbsent
          ? const Value.absent()
          : Value(likedAtSource),
      likedAtPrecision: likedAtPrecision == null && nullToAbsent
          ? const Value.absent()
          : Value(likedAtPrecision),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FavoriteProviderTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteProviderTrack(
      providerId: serializer.fromJson<String>(json['providerId']),
      refKey: serializer.fromJson<String>(json['refKey']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      rawLikedAt: serializer.fromJson<DateTime?>(json['rawLikedAt']),
      likedAtSource: serializer.fromJson<String?>(json['likedAtSource']),
      likedAtPrecision: serializer.fromJson<String?>(json['likedAtPrecision']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'refKey': serializer.toJson<String>(refKey),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'rawLikedAt': serializer.toJson<DateTime?>(rawLikedAt),
      'likedAtSource': serializer.toJson<String?>(likedAtSource),
      'likedAtPrecision': serializer.toJson<String?>(likedAtPrecision),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  FavoriteProviderTrack copyWith(
          {String? providerId,
          String? refKey,
          int? sortIndex,
          String? payloadJson,
          Value<DateTime?> rawLikedAt = const Value.absent(),
          Value<String?> likedAtSource = const Value.absent(),
          Value<String?> likedAtPrecision = const Value.absent(),
          DateTime? fetchedAt}) =>
      FavoriteProviderTrack(
        providerId: providerId ?? this.providerId,
        refKey: refKey ?? this.refKey,
        sortIndex: sortIndex ?? this.sortIndex,
        payloadJson: payloadJson ?? this.payloadJson,
        rawLikedAt: rawLikedAt.present ? rawLikedAt.value : this.rawLikedAt,
        likedAtSource:
            likedAtSource.present ? likedAtSource.value : this.likedAtSource,
        likedAtPrecision: likedAtPrecision.present
            ? likedAtPrecision.value
            : this.likedAtPrecision,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FavoriteProviderTrack copyWithCompanion(
      FavoriteProviderTracksCompanion data) {
    return FavoriteProviderTrack(
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      refKey: data.refKey.present ? data.refKey.value : this.refKey,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      rawLikedAt:
          data.rawLikedAt.present ? data.rawLikedAt.value : this.rawLikedAt,
      likedAtSource: data.likedAtSource.present
          ? data.likedAtSource.value
          : this.likedAtSource,
      likedAtPrecision: data.likedAtPrecision.present
          ? data.likedAtPrecision.value
          : this.likedAtPrecision,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteProviderTrack(')
          ..write('providerId: $providerId, ')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rawLikedAt: $rawLikedAt, ')
          ..write('likedAtSource: $likedAtSource, ')
          ..write('likedAtPrecision: $likedAtPrecision, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(providerId, refKey, sortIndex, payloadJson,
      rawLikedAt, likedAtSource, likedAtPrecision, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteProviderTrack &&
          other.providerId == this.providerId &&
          other.refKey == this.refKey &&
          other.sortIndex == this.sortIndex &&
          other.payloadJson == this.payloadJson &&
          other.rawLikedAt == this.rawLikedAt &&
          other.likedAtSource == this.likedAtSource &&
          other.likedAtPrecision == this.likedAtPrecision &&
          other.fetchedAt == this.fetchedAt);
}

class FavoriteProviderTracksCompanion
    extends UpdateCompanion<FavoriteProviderTrack> {
  final Value<String> providerId;
  final Value<String> refKey;
  final Value<int> sortIndex;
  final Value<String> payloadJson;
  final Value<DateTime?> rawLikedAt;
  final Value<String?> likedAtSource;
  final Value<String?> likedAtPrecision;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const FavoriteProviderTracksCompanion({
    this.providerId = const Value.absent(),
    this.refKey = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rawLikedAt = const Value.absent(),
    this.likedAtSource = const Value.absent(),
    this.likedAtPrecision = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteProviderTracksCompanion.insert({
    required String providerId,
    required String refKey,
    required int sortIndex,
    required String payloadJson,
    this.rawLikedAt = const Value.absent(),
    this.likedAtSource = const Value.absent(),
    this.likedAtPrecision = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : providerId = Value(providerId),
        refKey = Value(refKey),
        sortIndex = Value(sortIndex),
        payloadJson = Value(payloadJson),
        fetchedAt = Value(fetchedAt);
  static Insertable<FavoriteProviderTrack> custom({
    Expression<String>? providerId,
    Expression<String>? refKey,
    Expression<int>? sortIndex,
    Expression<String>? payloadJson,
    Expression<DateTime>? rawLikedAt,
    Expression<String>? likedAtSource,
    Expression<String>? likedAtPrecision,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (refKey != null) 'ref_key': refKey,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rawLikedAt != null) 'raw_liked_at': rawLikedAt,
      if (likedAtSource != null) 'liked_at_source': likedAtSource,
      if (likedAtPrecision != null) 'liked_at_precision': likedAtPrecision,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteProviderTracksCompanion copyWith(
      {Value<String>? providerId,
      Value<String>? refKey,
      Value<int>? sortIndex,
      Value<String>? payloadJson,
      Value<DateTime?>? rawLikedAt,
      Value<String?>? likedAtSource,
      Value<String?>? likedAtPrecision,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return FavoriteProviderTracksCompanion(
      providerId: providerId ?? this.providerId,
      refKey: refKey ?? this.refKey,
      sortIndex: sortIndex ?? this.sortIndex,
      payloadJson: payloadJson ?? this.payloadJson,
      rawLikedAt: rawLikedAt ?? this.rawLikedAt,
      likedAtSource: likedAtSource ?? this.likedAtSource,
      likedAtPrecision: likedAtPrecision ?? this.likedAtPrecision,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (refKey.present) {
      map['ref_key'] = Variable<String>(refKey.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rawLikedAt.present) {
      map['raw_liked_at'] = Variable<DateTime>(rawLikedAt.value);
    }
    if (likedAtSource.present) {
      map['liked_at_source'] = Variable<String>(likedAtSource.value);
    }
    if (likedAtPrecision.present) {
      map['liked_at_precision'] = Variable<String>(likedAtPrecision.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteProviderTracksCompanion(')
          ..write('providerId: $providerId, ')
          ..write('refKey: $refKey, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rawLikedAt: $rawLikedAt, ')
          ..write('likedAtSource: $likedAtSource, ')
          ..write('likedAtPrecision: $likedAtPrecision, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteLikedAtLedgerRowsTable extends FavoriteLikedAtLedgerRows
    with TableInfo<$FavoriteLikedAtLedgerRowsTable, FavoriteLikedAtLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteLikedAtLedgerRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityKeyMeta =
      const VerificationMeta('identityKey');
  @override
  late final GeneratedColumn<String> identityKey = GeneratedColumn<String>(
      'identity_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refJsonMeta =
      const VerificationMeta('refJson');
  @override
  late final GeneratedColumn<String> refJson = GeneratedColumn<String>(
      'ref_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [identityKey, refJson, metadataJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_liked_at_ledger_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<FavoriteLikedAtLedgerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_key')) {
      context.handle(
          _identityKeyMeta,
          identityKey.isAcceptableOrUnknown(
              data['identity_key']!, _identityKeyMeta));
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('ref_json')) {
      context.handle(_refJsonMeta,
          refJson.isAcceptableOrUnknown(data['ref_json']!, _refJsonMeta));
    } else if (isInserting) {
      context.missing(_refJsonMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityKey};
  @override
  FavoriteLikedAtLedgerRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteLikedAtLedgerRow(
      identityKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identity_key'])!,
      refJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_json'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $FavoriteLikedAtLedgerRowsTable createAlias(String alias) {
    return $FavoriteLikedAtLedgerRowsTable(attachedDatabase, alias);
  }
}

class FavoriteLikedAtLedgerRow extends DataClass
    implements Insertable<FavoriteLikedAtLedgerRow> {
  final String identityKey;
  final String refJson;
  final String metadataJson;
  final DateTime? updatedAt;
  const FavoriteLikedAtLedgerRow(
      {required this.identityKey,
      required this.refJson,
      required this.metadataJson,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_key'] = Variable<String>(identityKey);
    map['ref_json'] = Variable<String>(refJson);
    map['metadata_json'] = Variable<String>(metadataJson);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  FavoriteLikedAtLedgerRowsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteLikedAtLedgerRowsCompanion(
      identityKey: Value(identityKey),
      refJson: Value(refJson),
      metadataJson: Value(metadataJson),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory FavoriteLikedAtLedgerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteLikedAtLedgerRow(
      identityKey: serializer.fromJson<String>(json['identityKey']),
      refJson: serializer.fromJson<String>(json['refJson']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityKey': serializer.toJson<String>(identityKey),
      'refJson': serializer.toJson<String>(refJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  FavoriteLikedAtLedgerRow copyWith(
          {String? identityKey,
          String? refJson,
          String? metadataJson,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      FavoriteLikedAtLedgerRow(
        identityKey: identityKey ?? this.identityKey,
        refJson: refJson ?? this.refJson,
        metadataJson: metadataJson ?? this.metadataJson,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  FavoriteLikedAtLedgerRow copyWithCompanion(
      FavoriteLikedAtLedgerRowsCompanion data) {
    return FavoriteLikedAtLedgerRow(
      identityKey:
          data.identityKey.present ? data.identityKey.value : this.identityKey,
      refJson: data.refJson.present ? data.refJson.value : this.refJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteLikedAtLedgerRow(')
          ..write('identityKey: $identityKey, ')
          ..write('refJson: $refJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(identityKey, refJson, metadataJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteLikedAtLedgerRow &&
          other.identityKey == this.identityKey &&
          other.refJson == this.refJson &&
          other.metadataJson == this.metadataJson &&
          other.updatedAt == this.updatedAt);
}

class FavoriteLikedAtLedgerRowsCompanion
    extends UpdateCompanion<FavoriteLikedAtLedgerRow> {
  final Value<String> identityKey;
  final Value<String> refJson;
  final Value<String> metadataJson;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const FavoriteLikedAtLedgerRowsCompanion({
    this.identityKey = const Value.absent(),
    this.refJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteLikedAtLedgerRowsCompanion.insert({
    required String identityKey,
    required String refJson,
    required String metadataJson,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : identityKey = Value(identityKey),
        refJson = Value(refJson),
        metadataJson = Value(metadataJson);
  static Insertable<FavoriteLikedAtLedgerRow> custom({
    Expression<String>? identityKey,
    Expression<String>? refJson,
    Expression<String>? metadataJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityKey != null) 'identity_key': identityKey,
      if (refJson != null) 'ref_json': refJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteLikedAtLedgerRowsCompanion copyWith(
      {Value<String>? identityKey,
      Value<String>? refJson,
      Value<String>? metadataJson,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return FavoriteLikedAtLedgerRowsCompanion(
      identityKey: identityKey ?? this.identityKey,
      refJson: refJson ?? this.refJson,
      metadataJson: metadataJson ?? this.metadataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityKey.present) {
      map['identity_key'] = Variable<String>(identityKey.value);
    }
    if (refJson.present) {
      map['ref_json'] = Variable<String>(refJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteLikedAtLedgerRowsCompanion(')
          ..write('identityKey: $identityKey, ')
          ..write('refJson: $refJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnifiedFavoriteCacheRowsTable extends UnifiedFavoriteCacheRows
    with TableInfo<$UnifiedFavoriteCacheRowsTable, UnifiedFavoriteCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnifiedFavoriteCacheRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _unifiedIdMeta =
      const VerificationMeta('unifiedId');
  @override
  late final GeneratedColumn<String> unifiedId = GeneratedColumn<String>(
      'unified_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortLikedAtMeta =
      const VerificationMeta('sortLikedAt');
  @override
  late final GeneratedColumn<DateTime> sortLikedAt = GeneratedColumn<DateTime>(
      'sort_liked_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _builtAtMeta =
      const VerificationMeta('builtAt');
  @override
  late final GeneratedColumn<DateTime> builtAt = GeneratedColumn<DateTime>(
      'built_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [unifiedId, sortIndex, sortLikedAt, builtAt, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unified_favorite_cache_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<UnifiedFavoriteCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('unified_id')) {
      context.handle(_unifiedIdMeta,
          unifiedId.isAcceptableOrUnknown(data['unified_id']!, _unifiedIdMeta));
    } else if (isInserting) {
      context.missing(_unifiedIdMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('sort_liked_at')) {
      context.handle(
          _sortLikedAtMeta,
          sortLikedAt.isAcceptableOrUnknown(
              data['sort_liked_at']!, _sortLikedAtMeta));
    }
    if (data.containsKey('built_at')) {
      context.handle(_builtAtMeta,
          builtAt.isAcceptableOrUnknown(data['built_at']!, _builtAtMeta));
    } else if (isInserting) {
      context.missing(_builtAtMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {unifiedId};
  @override
  UnifiedFavoriteCacheRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnifiedFavoriteCacheRow(
      unifiedId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unified_id'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
      sortLikedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sort_liked_at']),
      builtAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}built_at'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
    );
  }

  @override
  $UnifiedFavoriteCacheRowsTable createAlias(String alias) {
    return $UnifiedFavoriteCacheRowsTable(attachedDatabase, alias);
  }
}

class UnifiedFavoriteCacheRow extends DataClass
    implements Insertable<UnifiedFavoriteCacheRow> {
  final String unifiedId;
  final int sortIndex;
  final DateTime? sortLikedAt;
  final DateTime builtAt;
  final String payloadJson;
  const UnifiedFavoriteCacheRow(
      {required this.unifiedId,
      required this.sortIndex,
      this.sortLikedAt,
      required this.builtAt,
      required this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['unified_id'] = Variable<String>(unifiedId);
    map['sort_index'] = Variable<int>(sortIndex);
    if (!nullToAbsent || sortLikedAt != null) {
      map['sort_liked_at'] = Variable<DateTime>(sortLikedAt);
    }
    map['built_at'] = Variable<DateTime>(builtAt);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  UnifiedFavoriteCacheRowsCompanion toCompanion(bool nullToAbsent) {
    return UnifiedFavoriteCacheRowsCompanion(
      unifiedId: Value(unifiedId),
      sortIndex: Value(sortIndex),
      sortLikedAt: sortLikedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sortLikedAt),
      builtAt: Value(builtAt),
      payloadJson: Value(payloadJson),
    );
  }

  factory UnifiedFavoriteCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnifiedFavoriteCacheRow(
      unifiedId: serializer.fromJson<String>(json['unifiedId']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      sortLikedAt: serializer.fromJson<DateTime?>(json['sortLikedAt']),
      builtAt: serializer.fromJson<DateTime>(json['builtAt']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'unifiedId': serializer.toJson<String>(unifiedId),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'sortLikedAt': serializer.toJson<DateTime?>(sortLikedAt),
      'builtAt': serializer.toJson<DateTime>(builtAt),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  UnifiedFavoriteCacheRow copyWith(
          {String? unifiedId,
          int? sortIndex,
          Value<DateTime?> sortLikedAt = const Value.absent(),
          DateTime? builtAt,
          String? payloadJson}) =>
      UnifiedFavoriteCacheRow(
        unifiedId: unifiedId ?? this.unifiedId,
        sortIndex: sortIndex ?? this.sortIndex,
        sortLikedAt: sortLikedAt.present ? sortLikedAt.value : this.sortLikedAt,
        builtAt: builtAt ?? this.builtAt,
        payloadJson: payloadJson ?? this.payloadJson,
      );
  UnifiedFavoriteCacheRow copyWithCompanion(
      UnifiedFavoriteCacheRowsCompanion data) {
    return UnifiedFavoriteCacheRow(
      unifiedId: data.unifiedId.present ? data.unifiedId.value : this.unifiedId,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      sortLikedAt:
          data.sortLikedAt.present ? data.sortLikedAt.value : this.sortLikedAt,
      builtAt: data.builtAt.present ? data.builtAt.value : this.builtAt,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedFavoriteCacheRow(')
          ..write('unifiedId: $unifiedId, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('sortLikedAt: $sortLikedAt, ')
          ..write('builtAt: $builtAt, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(unifiedId, sortIndex, sortLikedAt, builtAt, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnifiedFavoriteCacheRow &&
          other.unifiedId == this.unifiedId &&
          other.sortIndex == this.sortIndex &&
          other.sortLikedAt == this.sortLikedAt &&
          other.builtAt == this.builtAt &&
          other.payloadJson == this.payloadJson);
}

class UnifiedFavoriteCacheRowsCompanion
    extends UpdateCompanion<UnifiedFavoriteCacheRow> {
  final Value<String> unifiedId;
  final Value<int> sortIndex;
  final Value<DateTime?> sortLikedAt;
  final Value<DateTime> builtAt;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const UnifiedFavoriteCacheRowsCompanion({
    this.unifiedId = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.sortLikedAt = const Value.absent(),
    this.builtAt = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnifiedFavoriteCacheRowsCompanion.insert({
    required String unifiedId,
    required int sortIndex,
    this.sortLikedAt = const Value.absent(),
    required DateTime builtAt,
    required String payloadJson,
    this.rowid = const Value.absent(),
  })  : unifiedId = Value(unifiedId),
        sortIndex = Value(sortIndex),
        builtAt = Value(builtAt),
        payloadJson = Value(payloadJson);
  static Insertable<UnifiedFavoriteCacheRow> custom({
    Expression<String>? unifiedId,
    Expression<int>? sortIndex,
    Expression<DateTime>? sortLikedAt,
    Expression<DateTime>? builtAt,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (unifiedId != null) 'unified_id': unifiedId,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (sortLikedAt != null) 'sort_liked_at': sortLikedAt,
      if (builtAt != null) 'built_at': builtAt,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnifiedFavoriteCacheRowsCompanion copyWith(
      {Value<String>? unifiedId,
      Value<int>? sortIndex,
      Value<DateTime?>? sortLikedAt,
      Value<DateTime>? builtAt,
      Value<String>? payloadJson,
      Value<int>? rowid}) {
    return UnifiedFavoriteCacheRowsCompanion(
      unifiedId: unifiedId ?? this.unifiedId,
      sortIndex: sortIndex ?? this.sortIndex,
      sortLikedAt: sortLikedAt ?? this.sortLikedAt,
      builtAt: builtAt ?? this.builtAt,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (unifiedId.present) {
      map['unified_id'] = Variable<String>(unifiedId.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (sortLikedAt.present) {
      map['sort_liked_at'] = Variable<DateTime>(sortLikedAt.value);
    }
    if (builtAt.present) {
      map['built_at'] = Variable<DateTime>(builtAt.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedFavoriteCacheRowsCompanion(')
          ..write('unifiedId: $unifiedId, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('sortLikedAt: $sortLikedAt, ')
          ..write('builtAt: $builtAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteProviderStatesTable extends FavoriteProviderStates
    with TableInfo<$FavoriteProviderStatesTable, FavoriteProviderState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteProviderStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSuccessAtMeta =
      const VerificationMeta('lastSuccessAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>('last_success_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastFailureAtMeta =
      const VerificationMeta('lastFailureAt');
  @override
  late final GeneratedColumn<DateTime> lastFailureAt =
      GeneratedColumn<DateTime>('last_failure_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastFailureMessageMeta =
      const VerificationMeta('lastFailureMessage');
  @override
  late final GeneratedColumn<String> lastFailureMessage =
      GeneratedColumn<String>('last_failure_message', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [providerId, lastSuccessAt, lastFailureAt, lastFailureMessage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_provider_states';
  @override
  VerificationContext validateIntegrity(
      Insertable<FavoriteProviderState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
          _lastSuccessAtMeta,
          lastSuccessAt.isAcceptableOrUnknown(
              data['last_success_at']!, _lastSuccessAtMeta));
    }
    if (data.containsKey('last_failure_at')) {
      context.handle(
          _lastFailureAtMeta,
          lastFailureAt.isAcceptableOrUnknown(
              data['last_failure_at']!, _lastFailureAtMeta));
    }
    if (data.containsKey('last_failure_message')) {
      context.handle(
          _lastFailureMessageMeta,
          lastFailureMessage.isAcceptableOrUnknown(
              data['last_failure_message']!, _lastFailureMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId};
  @override
  FavoriteProviderState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteProviderState(
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      lastSuccessAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_success_at']),
      lastFailureAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_failure_at']),
      lastFailureMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_failure_message']),
    );
  }

  @override
  $FavoriteProviderStatesTable createAlias(String alias) {
    return $FavoriteProviderStatesTable(attachedDatabase, alias);
  }
}

class FavoriteProviderState extends DataClass
    implements Insertable<FavoriteProviderState> {
  final String providerId;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;
  final String? lastFailureMessage;
  const FavoriteProviderState(
      {required this.providerId,
      this.lastSuccessAt,
      this.lastFailureAt,
      this.lastFailureMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || lastFailureAt != null) {
      map['last_failure_at'] = Variable<DateTime>(lastFailureAt);
    }
    if (!nullToAbsent || lastFailureMessage != null) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage);
    }
    return map;
  }

  FavoriteProviderStatesCompanion toCompanion(bool nullToAbsent) {
    return FavoriteProviderStatesCompanion(
      providerId: Value(providerId),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      lastFailureAt: lastFailureAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureAt),
      lastFailureMessage: lastFailureMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureMessage),
    );
  }

  factory FavoriteProviderState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteProviderState(
      providerId: serializer.fromJson<String>(json['providerId']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      lastFailureAt: serializer.fromJson<DateTime?>(json['lastFailureAt']),
      lastFailureMessage:
          serializer.fromJson<String?>(json['lastFailureMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'lastFailureAt': serializer.toJson<DateTime?>(lastFailureAt),
      'lastFailureMessage': serializer.toJson<String?>(lastFailureMessage),
    };
  }

  FavoriteProviderState copyWith(
          {String? providerId,
          Value<DateTime?> lastSuccessAt = const Value.absent(),
          Value<DateTime?> lastFailureAt = const Value.absent(),
          Value<String?> lastFailureMessage = const Value.absent()}) =>
      FavoriteProviderState(
        providerId: providerId ?? this.providerId,
        lastSuccessAt:
            lastSuccessAt.present ? lastSuccessAt.value : this.lastSuccessAt,
        lastFailureAt:
            lastFailureAt.present ? lastFailureAt.value : this.lastFailureAt,
        lastFailureMessage: lastFailureMessage.present
            ? lastFailureMessage.value
            : this.lastFailureMessage,
      );
  FavoriteProviderState copyWithCompanion(
      FavoriteProviderStatesCompanion data) {
    return FavoriteProviderState(
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      lastFailureAt: data.lastFailureAt.present
          ? data.lastFailureAt.value
          : this.lastFailureAt,
      lastFailureMessage: data.lastFailureMessage.present
          ? data.lastFailureMessage.value
          : this.lastFailureMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteProviderState(')
          ..write('providerId: $providerId, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastFailureAt: $lastFailureAt, ')
          ..write('lastFailureMessage: $lastFailureMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, lastSuccessAt, lastFailureAt, lastFailureMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteProviderState &&
          other.providerId == this.providerId &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.lastFailureAt == this.lastFailureAt &&
          other.lastFailureMessage == this.lastFailureMessage);
}

class FavoriteProviderStatesCompanion
    extends UpdateCompanion<FavoriteProviderState> {
  final Value<String> providerId;
  final Value<DateTime?> lastSuccessAt;
  final Value<DateTime?> lastFailureAt;
  final Value<String?> lastFailureMessage;
  final Value<int> rowid;
  const FavoriteProviderStatesCompanion({
    this.providerId = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastFailureAt = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteProviderStatesCompanion.insert({
    required String providerId,
    this.lastSuccessAt = const Value.absent(),
    this.lastFailureAt = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId);
  static Insertable<FavoriteProviderState> custom({
    Expression<String>? providerId,
    Expression<DateTime>? lastSuccessAt,
    Expression<DateTime>? lastFailureAt,
    Expression<String>? lastFailureMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (lastFailureAt != null) 'last_failure_at': lastFailureAt,
      if (lastFailureMessage != null)
        'last_failure_message': lastFailureMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteProviderStatesCompanion copyWith(
      {Value<String>? providerId,
      Value<DateTime?>? lastSuccessAt,
      Value<DateTime?>? lastFailureAt,
      Value<String?>? lastFailureMessage,
      Value<int>? rowid}) {
    return FavoriteProviderStatesCompanion(
      providerId: providerId ?? this.providerId,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      lastFailureMessage: lastFailureMessage ?? this.lastFailureMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (lastFailureAt.present) {
      map['last_failure_at'] = Variable<DateTime>(lastFailureAt.value);
    }
    if (lastFailureMessage.present) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteProviderStatesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastFailureAt: $lastFailureAt, ')
          ..write('lastFailureMessage: $lastFailureMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredAudioCacheEntriesTable extends StoredAudioCacheEntries
    with TableInfo<$StoredAudioCacheEntriesTable, StoredAudioCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredAudioCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityKeyMeta =
      const VerificationMeta('identityKey');
  @override
  late final GeneratedColumn<String> identityKey = GeneratedColumn<String>(
      'identity_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
      'quality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        identityKey,
        providerId,
        trackId,
        quality,
        filePath,
        fileSize,
        completedAt,
        lastAccessedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_audio_cache_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredAudioCacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_key')) {
      context.handle(
          _identityKeyMeta,
          identityKey.isAcceptableOrUnknown(
              data['identity_key']!, _identityKeyMeta));
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityKey};
  @override
  StoredAudioCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredAudioCacheEntry(
      identityKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identity_key'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at'])!,
    );
  }

  @override
  $StoredAudioCacheEntriesTable createAlias(String alias) {
    return $StoredAudioCacheEntriesTable(attachedDatabase, alias);
  }
}

class StoredAudioCacheEntry extends DataClass
    implements Insertable<StoredAudioCacheEntry> {
  final String identityKey;
  final String providerId;
  final String trackId;
  final String quality;
  final String filePath;
  final int fileSize;
  final DateTime completedAt;
  final DateTime lastAccessedAt;
  const StoredAudioCacheEntry(
      {required this.identityKey,
      required this.providerId,
      required this.trackId,
      required this.quality,
      required this.filePath,
      required this.fileSize,
      required this.completedAt,
      required this.lastAccessedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_key'] = Variable<String>(identityKey);
    map['provider_id'] = Variable<String>(providerId);
    map['track_id'] = Variable<String>(trackId);
    map['quality'] = Variable<String>(quality);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  StoredAudioCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StoredAudioCacheEntriesCompanion(
      identityKey: Value(identityKey),
      providerId: Value(providerId),
      trackId: Value(trackId),
      quality: Value(quality),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      completedAt: Value(completedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory StoredAudioCacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredAudioCacheEntry(
      identityKey: serializer.fromJson<String>(json['identityKey']),
      providerId: serializer.fromJson<String>(json['providerId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      quality: serializer.fromJson<String>(json['quality']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityKey': serializer.toJson<String>(identityKey),
      'providerId': serializer.toJson<String>(providerId),
      'trackId': serializer.toJson<String>(trackId),
      'quality': serializer.toJson<String>(quality),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  StoredAudioCacheEntry copyWith(
          {String? identityKey,
          String? providerId,
          String? trackId,
          String? quality,
          String? filePath,
          int? fileSize,
          DateTime? completedAt,
          DateTime? lastAccessedAt}) =>
      StoredAudioCacheEntry(
        identityKey: identityKey ?? this.identityKey,
        providerId: providerId ?? this.providerId,
        trackId: trackId ?? this.trackId,
        quality: quality ?? this.quality,
        filePath: filePath ?? this.filePath,
        fileSize: fileSize ?? this.fileSize,
        completedAt: completedAt ?? this.completedAt,
        lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      );
  StoredAudioCacheEntry copyWithCompanion(
      StoredAudioCacheEntriesCompanion data) {
    return StoredAudioCacheEntry(
      identityKey:
          data.identityKey.present ? data.identityKey.value : this.identityKey,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      quality: data.quality.present ? data.quality.value : this.quality,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredAudioCacheEntry(')
          ..write('identityKey: $identityKey, ')
          ..write('providerId: $providerId, ')
          ..write('trackId: $trackId, ')
          ..write('quality: $quality, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(identityKey, providerId, trackId, quality,
      filePath, fileSize, completedAt, lastAccessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredAudioCacheEntry &&
          other.identityKey == this.identityKey &&
          other.providerId == this.providerId &&
          other.trackId == this.trackId &&
          other.quality == this.quality &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.completedAt == this.completedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class StoredAudioCacheEntriesCompanion
    extends UpdateCompanion<StoredAudioCacheEntry> {
  final Value<String> identityKey;
  final Value<String> providerId;
  final Value<String> trackId;
  final Value<String> quality;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<DateTime> completedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const StoredAudioCacheEntriesCompanion({
    this.identityKey = const Value.absent(),
    this.providerId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.quality = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredAudioCacheEntriesCompanion.insert({
    required String identityKey,
    required String providerId,
    required String trackId,
    required String quality,
    required String filePath,
    required int fileSize,
    required DateTime completedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  })  : identityKey = Value(identityKey),
        providerId = Value(providerId),
        trackId = Value(trackId),
        quality = Value(quality),
        filePath = Value(filePath),
        fileSize = Value(fileSize),
        completedAt = Value(completedAt),
        lastAccessedAt = Value(lastAccessedAt);
  static Insertable<StoredAudioCacheEntry> custom({
    Expression<String>? identityKey,
    Expression<String>? providerId,
    Expression<String>? trackId,
    Expression<String>? quality,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityKey != null) 'identity_key': identityKey,
      if (providerId != null) 'provider_id': providerId,
      if (trackId != null) 'track_id': trackId,
      if (quality != null) 'quality': quality,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (completedAt != null) 'completed_at': completedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredAudioCacheEntriesCompanion copyWith(
      {Value<String>? identityKey,
      Value<String>? providerId,
      Value<String>? trackId,
      Value<String>? quality,
      Value<String>? filePath,
      Value<int>? fileSize,
      Value<DateTime>? completedAt,
      Value<DateTime>? lastAccessedAt,
      Value<int>? rowid}) {
    return StoredAudioCacheEntriesCompanion(
      identityKey: identityKey ?? this.identityKey,
      providerId: providerId ?? this.providerId,
      trackId: trackId ?? this.trackId,
      quality: quality ?? this.quality,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityKey.present) {
      map['identity_key'] = Variable<String>(identityKey.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredAudioCacheEntriesCompanion(')
          ..write('identityKey: $identityKey, ')
          ..write('providerId: $providerId, ')
          ..write('trackId: $trackId, ')
          ..write('quality: $quality, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioCacheSettingsTable extends AudioCacheSettings
    with TableInfo<$AudioCacheSettingsTable, AudioCacheSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCacheSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'));
  static const VerificationMeta _wifiOnlyMeta =
      const VerificationMeta('wifiOnly');
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
      'wifi_only', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wifi_only" IN (0, 1))'));
  static const VerificationMeta _maxBytesMeta =
      const VerificationMeta('maxBytes');
  @override
  late final GeneratedColumn<int> maxBytes = GeneratedColumn<int>(
      'max_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, enabled, wifiOnly, maxBytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_cache_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AudioCacheSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('wifi_only')) {
      context.handle(_wifiOnlyMeta,
          wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta));
    } else if (isInserting) {
      context.missing(_wifiOnlyMeta);
    }
    if (data.containsKey('max_bytes')) {
      context.handle(_maxBytesMeta,
          maxBytes.isAcceptableOrUnknown(data['max_bytes']!, _maxBytesMeta));
    } else if (isInserting) {
      context.missing(_maxBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioCacheSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCacheSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      wifiOnly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}wifi_only'])!,
      maxBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_bytes'])!,
    );
  }

  @override
  $AudioCacheSettingsTable createAlias(String alias) {
    return $AudioCacheSettingsTable(attachedDatabase, alias);
  }
}

class AudioCacheSetting extends DataClass
    implements Insertable<AudioCacheSetting> {
  final int id;
  final bool enabled;
  final bool wifiOnly;
  final int maxBytes;
  const AudioCacheSetting(
      {required this.id,
      required this.enabled,
      required this.wifiOnly,
      required this.maxBytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['max_bytes'] = Variable<int>(maxBytes);
    return map;
  }

  AudioCacheSettingsCompanion toCompanion(bool nullToAbsent) {
    return AudioCacheSettingsCompanion(
      id: Value(id),
      enabled: Value(enabled),
      wifiOnly: Value(wifiOnly),
      maxBytes: Value(maxBytes),
    );
  }

  factory AudioCacheSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCacheSetting(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      maxBytes: serializer.fromJson<int>(json['maxBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'maxBytes': serializer.toJson<int>(maxBytes),
    };
  }

  AudioCacheSetting copyWith(
          {int? id, bool? enabled, bool? wifiOnly, int? maxBytes}) =>
      AudioCacheSetting(
        id: id ?? this.id,
        enabled: enabled ?? this.enabled,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        maxBytes: maxBytes ?? this.maxBytes,
      );
  AudioCacheSetting copyWithCompanion(AudioCacheSettingsCompanion data) {
    return AudioCacheSetting(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      maxBytes: data.maxBytes.present ? data.maxBytes.value : this.maxBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheSetting(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('maxBytes: $maxBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, enabled, wifiOnly, maxBytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCacheSetting &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.wifiOnly == this.wifiOnly &&
          other.maxBytes == this.maxBytes);
}

class AudioCacheSettingsCompanion extends UpdateCompanion<AudioCacheSetting> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<bool> wifiOnly;
  final Value<int> maxBytes;
  const AudioCacheSettingsCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.maxBytes = const Value.absent(),
  });
  AudioCacheSettingsCompanion.insert({
    this.id = const Value.absent(),
    required bool enabled,
    required bool wifiOnly,
    required int maxBytes,
  })  : enabled = Value(enabled),
        wifiOnly = Value(wifiOnly),
        maxBytes = Value(maxBytes);
  static Insertable<AudioCacheSetting> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<bool>? wifiOnly,
    Expression<int>? maxBytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (maxBytes != null) 'max_bytes': maxBytes,
    });
  }

  AudioCacheSettingsCompanion copyWith(
      {Value<int>? id,
      Value<bool>? enabled,
      Value<bool>? wifiOnly,
      Value<int>? maxBytes}) {
    return AudioCacheSettingsCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxBytes: maxBytes ?? this.maxBytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (maxBytes.present) {
      map['max_bytes'] = Variable<int>(maxBytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheSettingsCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('maxBytes: $maxBytes')
          ..write(')'))
        .toString();
  }
}

abstract class _$MeloDriftDatabase extends GeneratedDatabase {
  _$MeloDriftDatabase(QueryExecutor e) : super(e);
  $MeloDriftDatabaseManager get managers => $MeloDriftDatabaseManager(this);
  late final $MeloMetaRowsTable meloMetaRows = $MeloMetaRowsTable(this);
  late final $StoredPlaylistsTable storedPlaylists =
      $StoredPlaylistsTable(this);
  late final $StoredDownloadTasksTable storedDownloadTasks =
      $StoredDownloadTasksTable(this);
  late final $StoredLocalMediaItemsTable storedLocalMediaItems =
      $StoredLocalMediaItemsTable(this);
  late final $StoredFavoriteOverridesTable storedFavoriteOverrides =
      $StoredFavoriteOverridesTable(this);
  late final $FavoriteProviderTracksTable favoriteProviderTracks =
      $FavoriteProviderTracksTable(this);
  late final $FavoriteLikedAtLedgerRowsTable favoriteLikedAtLedgerRows =
      $FavoriteLikedAtLedgerRowsTable(this);
  late final $UnifiedFavoriteCacheRowsTable unifiedFavoriteCacheRows =
      $UnifiedFavoriteCacheRowsTable(this);
  late final $FavoriteProviderStatesTable favoriteProviderStates =
      $FavoriteProviderStatesTable(this);
  late final $StoredAudioCacheEntriesTable storedAudioCacheEntries =
      $StoredAudioCacheEntriesTable(this);
  late final $AudioCacheSettingsTable audioCacheSettings =
      $AudioCacheSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        meloMetaRows,
        storedPlaylists,
        storedDownloadTasks,
        storedLocalMediaItems,
        storedFavoriteOverrides,
        favoriteProviderTracks,
        favoriteLikedAtLedgerRows,
        unifiedFavoriteCacheRows,
        favoriteProviderStates,
        storedAudioCacheEntries,
        audioCacheSettings
      ];
}

typedef $$MeloMetaRowsTableCreateCompanionBuilder = MeloMetaRowsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MeloMetaRowsTableUpdateCompanionBuilder = MeloMetaRowsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MeloMetaRowsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $MeloMetaRowsTable> {
  $$MeloMetaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$MeloMetaRowsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $MeloMetaRowsTable> {
  $$MeloMetaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$MeloMetaRowsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $MeloMetaRowsTable> {
  $$MeloMetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MeloMetaRowsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $MeloMetaRowsTable,
    MeloMetaRow,
    $$MeloMetaRowsTableFilterComposer,
    $$MeloMetaRowsTableOrderingComposer,
    $$MeloMetaRowsTableAnnotationComposer,
    $$MeloMetaRowsTableCreateCompanionBuilder,
    $$MeloMetaRowsTableUpdateCompanionBuilder,
    (
      MeloMetaRow,
      BaseReferences<_$MeloDriftDatabase, $MeloMetaRowsTable, MeloMetaRow>
    ),
    MeloMetaRow,
    PrefetchHooks Function()> {
  $$MeloMetaRowsTableTableManager(
      _$MeloDriftDatabase db, $MeloMetaRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeloMetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeloMetaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeloMetaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeloMetaRowsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              MeloMetaRowsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeloMetaRowsTableProcessedTableManager = ProcessedTableManager<
    _$MeloDriftDatabase,
    $MeloMetaRowsTable,
    MeloMetaRow,
    $$MeloMetaRowsTableFilterComposer,
    $$MeloMetaRowsTableOrderingComposer,
    $$MeloMetaRowsTableAnnotationComposer,
    $$MeloMetaRowsTableCreateCompanionBuilder,
    $$MeloMetaRowsTableUpdateCompanionBuilder,
    (
      MeloMetaRow,
      BaseReferences<_$MeloDriftDatabase, $MeloMetaRowsTable, MeloMetaRow>
    ),
    MeloMetaRow,
    PrefetchHooks Function()>;
typedef $$StoredPlaylistsTableCreateCompanionBuilder = StoredPlaylistsCompanion
    Function({
  required String id,
  required int sortIndex,
  required String payloadJson,
  Value<int> rowid,
});
typedef $$StoredPlaylistsTableUpdateCompanionBuilder = StoredPlaylistsCompanion
    Function({
  Value<String> id,
  Value<int> sortIndex,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $$StoredPlaylistsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$StoredPlaylistsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$StoredPlaylistsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$StoredPlaylistsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredPlaylistsTable,
    StoredPlaylist,
    $$StoredPlaylistsTableFilterComposer,
    $$StoredPlaylistsTableOrderingComposer,
    $$StoredPlaylistsTableAnnotationComposer,
    $$StoredPlaylistsTableCreateCompanionBuilder,
    $$StoredPlaylistsTableUpdateCompanionBuilder,
    (
      StoredPlaylist,
      BaseReferences<_$MeloDriftDatabase, $StoredPlaylistsTable, StoredPlaylist>
    ),
    StoredPlaylist,
    PrefetchHooks Function()> {
  $$StoredPlaylistsTableTableManager(
      _$MeloDriftDatabase db, $StoredPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredPlaylistsCompanion(
            id: id,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int sortIndex,
            required String payloadJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredPlaylistsCompanion.insert(
            id: id,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredPlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$MeloDriftDatabase,
    $StoredPlaylistsTable,
    StoredPlaylist,
    $$StoredPlaylistsTableFilterComposer,
    $$StoredPlaylistsTableOrderingComposer,
    $$StoredPlaylistsTableAnnotationComposer,
    $$StoredPlaylistsTableCreateCompanionBuilder,
    $$StoredPlaylistsTableUpdateCompanionBuilder,
    (
      StoredPlaylist,
      BaseReferences<_$MeloDriftDatabase, $StoredPlaylistsTable, StoredPlaylist>
    ),
    StoredPlaylist,
    PrefetchHooks Function()>;
typedef $$StoredDownloadTasksTableCreateCompanionBuilder
    = StoredDownloadTasksCompanion Function({
  required String refKey,
  required int sortIndex,
  required String payloadJson,
  Value<int> rowid,
});
typedef $$StoredDownloadTasksTableUpdateCompanionBuilder
    = StoredDownloadTasksCompanion Function({
  Value<String> refKey,
  Value<int> sortIndex,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $$StoredDownloadTasksTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredDownloadTasksTable> {
  $$StoredDownloadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$StoredDownloadTasksTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredDownloadTasksTable> {
  $$StoredDownloadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$StoredDownloadTasksTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredDownloadTasksTable> {
  $$StoredDownloadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get refKey =>
      $composableBuilder(column: $table.refKey, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$StoredDownloadTasksTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredDownloadTasksTable,
    StoredDownloadTask,
    $$StoredDownloadTasksTableFilterComposer,
    $$StoredDownloadTasksTableOrderingComposer,
    $$StoredDownloadTasksTableAnnotationComposer,
    $$StoredDownloadTasksTableCreateCompanionBuilder,
    $$StoredDownloadTasksTableUpdateCompanionBuilder,
    (
      StoredDownloadTask,
      BaseReferences<_$MeloDriftDatabase, $StoredDownloadTasksTable,
          StoredDownloadTask>
    ),
    StoredDownloadTask,
    PrefetchHooks Function()> {
  $$StoredDownloadTasksTableTableManager(
      _$MeloDriftDatabase db, $StoredDownloadTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredDownloadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredDownloadTasksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredDownloadTasksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> refKey = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredDownloadTasksCompanion(
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String refKey,
            required int sortIndex,
            required String payloadJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredDownloadTasksCompanion.insert(
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredDownloadTasksTableProcessedTableManager = ProcessedTableManager<
    _$MeloDriftDatabase,
    $StoredDownloadTasksTable,
    StoredDownloadTask,
    $$StoredDownloadTasksTableFilterComposer,
    $$StoredDownloadTasksTableOrderingComposer,
    $$StoredDownloadTasksTableAnnotationComposer,
    $$StoredDownloadTasksTableCreateCompanionBuilder,
    $$StoredDownloadTasksTableUpdateCompanionBuilder,
    (
      StoredDownloadTask,
      BaseReferences<_$MeloDriftDatabase, $StoredDownloadTasksTable,
          StoredDownloadTask>
    ),
    StoredDownloadTask,
    PrefetchHooks Function()>;
typedef $$StoredLocalMediaItemsTableCreateCompanionBuilder
    = StoredLocalMediaItemsCompanion Function({
  required String refKey,
  required int sortIndex,
  required String payloadJson,
  Value<int> rowid,
});
typedef $$StoredLocalMediaItemsTableUpdateCompanionBuilder
    = StoredLocalMediaItemsCompanion Function({
  Value<String> refKey,
  Value<int> sortIndex,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $$StoredLocalMediaItemsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalMediaItemsTable> {
  $$StoredLocalMediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalMediaItemsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalMediaItemsTable> {
  $$StoredLocalMediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalMediaItemsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalMediaItemsTable> {
  $$StoredLocalMediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get refKey =>
      $composableBuilder(column: $table.refKey, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$StoredLocalMediaItemsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalMediaItemsTable,
    StoredLocalMediaItem,
    $$StoredLocalMediaItemsTableFilterComposer,
    $$StoredLocalMediaItemsTableOrderingComposer,
    $$StoredLocalMediaItemsTableAnnotationComposer,
    $$StoredLocalMediaItemsTableCreateCompanionBuilder,
    $$StoredLocalMediaItemsTableUpdateCompanionBuilder,
    (
      StoredLocalMediaItem,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalMediaItemsTable,
          StoredLocalMediaItem>
    ),
    StoredLocalMediaItem,
    PrefetchHooks Function()> {
  $$StoredLocalMediaItemsTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalMediaItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalMediaItemsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalMediaItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalMediaItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> refKey = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalMediaItemsCompanion(
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String refKey,
            required int sortIndex,
            required String payloadJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalMediaItemsCompanion.insert(
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalMediaItemsTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalMediaItemsTable,
        StoredLocalMediaItem,
        $$StoredLocalMediaItemsTableFilterComposer,
        $$StoredLocalMediaItemsTableOrderingComposer,
        $$StoredLocalMediaItemsTableAnnotationComposer,
        $$StoredLocalMediaItemsTableCreateCompanionBuilder,
        $$StoredLocalMediaItemsTableUpdateCompanionBuilder,
        (
          StoredLocalMediaItem,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalMediaItemsTable,
              StoredLocalMediaItem>
        ),
        StoredLocalMediaItem,
        PrefetchHooks Function()>;
typedef $$StoredFavoriteOverridesTableCreateCompanionBuilder
    = StoredFavoriteOverridesCompanion Function({
  required String id,
  required String kind,
  required int sortIndex,
  required String payloadJson,
  Value<int> rowid,
});
typedef $$StoredFavoriteOverridesTableUpdateCompanionBuilder
    = StoredFavoriteOverridesCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<int> sortIndex,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $$StoredFavoriteOverridesTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredFavoriteOverridesTable> {
  $$StoredFavoriteOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$StoredFavoriteOverridesTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredFavoriteOverridesTable> {
  $$StoredFavoriteOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$StoredFavoriteOverridesTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredFavoriteOverridesTable> {
  $$StoredFavoriteOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$StoredFavoriteOverridesTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredFavoriteOverridesTable,
    StoredFavoriteOverride,
    $$StoredFavoriteOverridesTableFilterComposer,
    $$StoredFavoriteOverridesTableOrderingComposer,
    $$StoredFavoriteOverridesTableAnnotationComposer,
    $$StoredFavoriteOverridesTableCreateCompanionBuilder,
    $$StoredFavoriteOverridesTableUpdateCompanionBuilder,
    (
      StoredFavoriteOverride,
      BaseReferences<_$MeloDriftDatabase, $StoredFavoriteOverridesTable,
          StoredFavoriteOverride>
    ),
    StoredFavoriteOverride,
    PrefetchHooks Function()> {
  $$StoredFavoriteOverridesTableTableManager(
      _$MeloDriftDatabase db, $StoredFavoriteOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredFavoriteOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredFavoriteOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredFavoriteOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredFavoriteOverridesCompanion(
            id: id,
            kind: kind,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required int sortIndex,
            required String payloadJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredFavoriteOverridesCompanion.insert(
            id: id,
            kind: kind,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredFavoriteOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredFavoriteOverridesTable,
        StoredFavoriteOverride,
        $$StoredFavoriteOverridesTableFilterComposer,
        $$StoredFavoriteOverridesTableOrderingComposer,
        $$StoredFavoriteOverridesTableAnnotationComposer,
        $$StoredFavoriteOverridesTableCreateCompanionBuilder,
        $$StoredFavoriteOverridesTableUpdateCompanionBuilder,
        (
          StoredFavoriteOverride,
          BaseReferences<_$MeloDriftDatabase, $StoredFavoriteOverridesTable,
              StoredFavoriteOverride>
        ),
        StoredFavoriteOverride,
        PrefetchHooks Function()>;
typedef $$FavoriteProviderTracksTableCreateCompanionBuilder
    = FavoriteProviderTracksCompanion Function({
  required String providerId,
  required String refKey,
  required int sortIndex,
  required String payloadJson,
  Value<DateTime?> rawLikedAt,
  Value<String?> likedAtSource,
  Value<String?> likedAtPrecision,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$FavoriteProviderTracksTableUpdateCompanionBuilder
    = FavoriteProviderTracksCompanion Function({
  Value<String> providerId,
  Value<String> refKey,
  Value<int> sortIndex,
  Value<String> payloadJson,
  Value<DateTime?> rawLikedAt,
  Value<String?> likedAtSource,
  Value<String?> likedAtPrecision,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$FavoriteProviderTracksTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderTracksTable> {
  $$FavoriteProviderTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get rawLikedAt => $composableBuilder(
      column: $table.rawLikedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get likedAtSource => $composableBuilder(
      column: $table.likedAtSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get likedAtPrecision => $composableBuilder(
      column: $table.likedAtPrecision,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$FavoriteProviderTracksTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderTracksTable> {
  $$FavoriteProviderTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refKey => $composableBuilder(
      column: $table.refKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get rawLikedAt => $composableBuilder(
      column: $table.rawLikedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get likedAtSource => $composableBuilder(
      column: $table.likedAtSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get likedAtPrecision => $composableBuilder(
      column: $table.likedAtPrecision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteProviderTracksTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderTracksTable> {
  $$FavoriteProviderTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get refKey =>
      $composableBuilder(column: $table.refKey, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get rawLikedAt => $composableBuilder(
      column: $table.rawLikedAt, builder: (column) => column);

  GeneratedColumn<String> get likedAtSource => $composableBuilder(
      column: $table.likedAtSource, builder: (column) => column);

  GeneratedColumn<String> get likedAtPrecision => $composableBuilder(
      column: $table.likedAtPrecision, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FavoriteProviderTracksTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $FavoriteProviderTracksTable,
    FavoriteProviderTrack,
    $$FavoriteProviderTracksTableFilterComposer,
    $$FavoriteProviderTracksTableOrderingComposer,
    $$FavoriteProviderTracksTableAnnotationComposer,
    $$FavoriteProviderTracksTableCreateCompanionBuilder,
    $$FavoriteProviderTracksTableUpdateCompanionBuilder,
    (
      FavoriteProviderTrack,
      BaseReferences<_$MeloDriftDatabase, $FavoriteProviderTracksTable,
          FavoriteProviderTrack>
    ),
    FavoriteProviderTrack,
    PrefetchHooks Function()> {
  $$FavoriteProviderTracksTableTableManager(
      _$MeloDriftDatabase db, $FavoriteProviderTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteProviderTracksTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteProviderTracksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteProviderTracksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> providerId = const Value.absent(),
            Value<String> refKey = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime?> rawLikedAt = const Value.absent(),
            Value<String?> likedAtSource = const Value.absent(),
            Value<String?> likedAtPrecision = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteProviderTracksCompanion(
            providerId: providerId,
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rawLikedAt: rawLikedAt,
            likedAtSource: likedAtSource,
            likedAtPrecision: likedAtPrecision,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            required String refKey,
            required int sortIndex,
            required String payloadJson,
            Value<DateTime?> rawLikedAt = const Value.absent(),
            Value<String?> likedAtSource = const Value.absent(),
            Value<String?> likedAtPrecision = const Value.absent(),
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteProviderTracksCompanion.insert(
            providerId: providerId,
            refKey: refKey,
            sortIndex: sortIndex,
            payloadJson: payloadJson,
            rawLikedAt: rawLikedAt,
            likedAtSource: likedAtSource,
            likedAtPrecision: likedAtPrecision,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteProviderTracksTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $FavoriteProviderTracksTable,
        FavoriteProviderTrack,
        $$FavoriteProviderTracksTableFilterComposer,
        $$FavoriteProviderTracksTableOrderingComposer,
        $$FavoriteProviderTracksTableAnnotationComposer,
        $$FavoriteProviderTracksTableCreateCompanionBuilder,
        $$FavoriteProviderTracksTableUpdateCompanionBuilder,
        (
          FavoriteProviderTrack,
          BaseReferences<_$MeloDriftDatabase, $FavoriteProviderTracksTable,
              FavoriteProviderTrack>
        ),
        FavoriteProviderTrack,
        PrefetchHooks Function()>;
typedef $$FavoriteLikedAtLedgerRowsTableCreateCompanionBuilder
    = FavoriteLikedAtLedgerRowsCompanion Function({
  required String identityKey,
  required String refJson,
  required String metadataJson,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$FavoriteLikedAtLedgerRowsTableUpdateCompanionBuilder
    = FavoriteLikedAtLedgerRowsCompanion Function({
  Value<String> identityKey,
  Value<String> refJson,
  Value<String> metadataJson,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$FavoriteLikedAtLedgerRowsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteLikedAtLedgerRowsTable> {
  $$FavoriteLikedAtLedgerRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refJson => $composableBuilder(
      column: $table.refJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FavoriteLikedAtLedgerRowsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteLikedAtLedgerRowsTable> {
  $$FavoriteLikedAtLedgerRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refJson => $composableBuilder(
      column: $table.refJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteLikedAtLedgerRowsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteLikedAtLedgerRowsTable> {
  $$FavoriteLikedAtLedgerRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => column);

  GeneratedColumn<String> get refJson =>
      $composableBuilder(column: $table.refJson, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FavoriteLikedAtLedgerRowsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $FavoriteLikedAtLedgerRowsTable,
    FavoriteLikedAtLedgerRow,
    $$FavoriteLikedAtLedgerRowsTableFilterComposer,
    $$FavoriteLikedAtLedgerRowsTableOrderingComposer,
    $$FavoriteLikedAtLedgerRowsTableAnnotationComposer,
    $$FavoriteLikedAtLedgerRowsTableCreateCompanionBuilder,
    $$FavoriteLikedAtLedgerRowsTableUpdateCompanionBuilder,
    (
      FavoriteLikedAtLedgerRow,
      BaseReferences<_$MeloDriftDatabase, $FavoriteLikedAtLedgerRowsTable,
          FavoriteLikedAtLedgerRow>
    ),
    FavoriteLikedAtLedgerRow,
    PrefetchHooks Function()> {
  $$FavoriteLikedAtLedgerRowsTableTableManager(
      _$MeloDriftDatabase db, $FavoriteLikedAtLedgerRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteLikedAtLedgerRowsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteLikedAtLedgerRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteLikedAtLedgerRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> identityKey = const Value.absent(),
            Value<String> refJson = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteLikedAtLedgerRowsCompanion(
            identityKey: identityKey,
            refJson: refJson,
            metadataJson: metadataJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String identityKey,
            required String refJson,
            required String metadataJson,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteLikedAtLedgerRowsCompanion.insert(
            identityKey: identityKey,
            refJson: refJson,
            metadataJson: metadataJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteLikedAtLedgerRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $FavoriteLikedAtLedgerRowsTable,
        FavoriteLikedAtLedgerRow,
        $$FavoriteLikedAtLedgerRowsTableFilterComposer,
        $$FavoriteLikedAtLedgerRowsTableOrderingComposer,
        $$FavoriteLikedAtLedgerRowsTableAnnotationComposer,
        $$FavoriteLikedAtLedgerRowsTableCreateCompanionBuilder,
        $$FavoriteLikedAtLedgerRowsTableUpdateCompanionBuilder,
        (
          FavoriteLikedAtLedgerRow,
          BaseReferences<_$MeloDriftDatabase, $FavoriteLikedAtLedgerRowsTable,
              FavoriteLikedAtLedgerRow>
        ),
        FavoriteLikedAtLedgerRow,
        PrefetchHooks Function()>;
typedef $$UnifiedFavoriteCacheRowsTableCreateCompanionBuilder
    = UnifiedFavoriteCacheRowsCompanion Function({
  required String unifiedId,
  required int sortIndex,
  Value<DateTime?> sortLikedAt,
  required DateTime builtAt,
  required String payloadJson,
  Value<int> rowid,
});
typedef $$UnifiedFavoriteCacheRowsTableUpdateCompanionBuilder
    = UnifiedFavoriteCacheRowsCompanion Function({
  Value<String> unifiedId,
  Value<int> sortIndex,
  Value<DateTime?> sortLikedAt,
  Value<DateTime> builtAt,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $$UnifiedFavoriteCacheRowsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $UnifiedFavoriteCacheRowsTable> {
  $$UnifiedFavoriteCacheRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get unifiedId => $composableBuilder(
      column: $table.unifiedId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sortLikedAt => $composableBuilder(
      column: $table.sortLikedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get builtAt => $composableBuilder(
      column: $table.builtAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$UnifiedFavoriteCacheRowsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $UnifiedFavoriteCacheRowsTable> {
  $$UnifiedFavoriteCacheRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get unifiedId => $composableBuilder(
      column: $table.unifiedId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sortLikedAt => $composableBuilder(
      column: $table.sortLikedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get builtAt => $composableBuilder(
      column: $table.builtAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$UnifiedFavoriteCacheRowsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $UnifiedFavoriteCacheRowsTable> {
  $$UnifiedFavoriteCacheRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get unifiedId =>
      $composableBuilder(column: $table.unifiedId, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get sortLikedAt => $composableBuilder(
      column: $table.sortLikedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get builtAt =>
      $composableBuilder(column: $table.builtAt, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$UnifiedFavoriteCacheRowsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $UnifiedFavoriteCacheRowsTable,
    UnifiedFavoriteCacheRow,
    $$UnifiedFavoriteCacheRowsTableFilterComposer,
    $$UnifiedFavoriteCacheRowsTableOrderingComposer,
    $$UnifiedFavoriteCacheRowsTableAnnotationComposer,
    $$UnifiedFavoriteCacheRowsTableCreateCompanionBuilder,
    $$UnifiedFavoriteCacheRowsTableUpdateCompanionBuilder,
    (
      UnifiedFavoriteCacheRow,
      BaseReferences<_$MeloDriftDatabase, $UnifiedFavoriteCacheRowsTable,
          UnifiedFavoriteCacheRow>
    ),
    UnifiedFavoriteCacheRow,
    PrefetchHooks Function()> {
  $$UnifiedFavoriteCacheRowsTableTableManager(
      _$MeloDriftDatabase db, $UnifiedFavoriteCacheRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnifiedFavoriteCacheRowsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UnifiedFavoriteCacheRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnifiedFavoriteCacheRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> unifiedId = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<DateTime?> sortLikedAt = const Value.absent(),
            Value<DateTime> builtAt = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnifiedFavoriteCacheRowsCompanion(
            unifiedId: unifiedId,
            sortIndex: sortIndex,
            sortLikedAt: sortLikedAt,
            builtAt: builtAt,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String unifiedId,
            required int sortIndex,
            Value<DateTime?> sortLikedAt = const Value.absent(),
            required DateTime builtAt,
            required String payloadJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnifiedFavoriteCacheRowsCompanion.insert(
            unifiedId: unifiedId,
            sortIndex: sortIndex,
            sortLikedAt: sortLikedAt,
            builtAt: builtAt,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnifiedFavoriteCacheRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $UnifiedFavoriteCacheRowsTable,
        UnifiedFavoriteCacheRow,
        $$UnifiedFavoriteCacheRowsTableFilterComposer,
        $$UnifiedFavoriteCacheRowsTableOrderingComposer,
        $$UnifiedFavoriteCacheRowsTableAnnotationComposer,
        $$UnifiedFavoriteCacheRowsTableCreateCompanionBuilder,
        $$UnifiedFavoriteCacheRowsTableUpdateCompanionBuilder,
        (
          UnifiedFavoriteCacheRow,
          BaseReferences<_$MeloDriftDatabase, $UnifiedFavoriteCacheRowsTable,
              UnifiedFavoriteCacheRow>
        ),
        UnifiedFavoriteCacheRow,
        PrefetchHooks Function()>;
typedef $$FavoriteProviderStatesTableCreateCompanionBuilder
    = FavoriteProviderStatesCompanion Function({
  required String providerId,
  Value<DateTime?> lastSuccessAt,
  Value<DateTime?> lastFailureAt,
  Value<String?> lastFailureMessage,
  Value<int> rowid,
});
typedef $$FavoriteProviderStatesTableUpdateCompanionBuilder
    = FavoriteProviderStatesCompanion Function({
  Value<String> providerId,
  Value<DateTime?> lastSuccessAt,
  Value<DateTime?> lastFailureAt,
  Value<String?> lastFailureMessage,
  Value<int> rowid,
});

class $$FavoriteProviderStatesTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderStatesTable> {
  $$FavoriteProviderStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFailureAt => $composableBuilder(
      column: $table.lastFailureAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastFailureMessage => $composableBuilder(
      column: $table.lastFailureMessage,
      builder: (column) => ColumnFilters(column));
}

class $$FavoriteProviderStatesTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderStatesTable> {
  $$FavoriteProviderStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFailureAt => $composableBuilder(
      column: $table.lastFailureAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastFailureMessage => $composableBuilder(
      column: $table.lastFailureMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$FavoriteProviderStatesTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $FavoriteProviderStatesTable> {
  $$FavoriteProviderStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFailureAt => $composableBuilder(
      column: $table.lastFailureAt, builder: (column) => column);

  GeneratedColumn<String> get lastFailureMessage => $composableBuilder(
      column: $table.lastFailureMessage, builder: (column) => column);
}

class $$FavoriteProviderStatesTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $FavoriteProviderStatesTable,
    FavoriteProviderState,
    $$FavoriteProviderStatesTableFilterComposer,
    $$FavoriteProviderStatesTableOrderingComposer,
    $$FavoriteProviderStatesTableAnnotationComposer,
    $$FavoriteProviderStatesTableCreateCompanionBuilder,
    $$FavoriteProviderStatesTableUpdateCompanionBuilder,
    (
      FavoriteProviderState,
      BaseReferences<_$MeloDriftDatabase, $FavoriteProviderStatesTable,
          FavoriteProviderState>
    ),
    FavoriteProviderState,
    PrefetchHooks Function()> {
  $$FavoriteProviderStatesTableTableManager(
      _$MeloDriftDatabase db, $FavoriteProviderStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteProviderStatesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteProviderStatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteProviderStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> providerId = const Value.absent(),
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<DateTime?> lastFailureAt = const Value.absent(),
            Value<String?> lastFailureMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteProviderStatesCompanion(
            providerId: providerId,
            lastSuccessAt: lastSuccessAt,
            lastFailureAt: lastFailureAt,
            lastFailureMessage: lastFailureMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<DateTime?> lastFailureAt = const Value.absent(),
            Value<String?> lastFailureMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteProviderStatesCompanion.insert(
            providerId: providerId,
            lastSuccessAt: lastSuccessAt,
            lastFailureAt: lastFailureAt,
            lastFailureMessage: lastFailureMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteProviderStatesTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $FavoriteProviderStatesTable,
        FavoriteProviderState,
        $$FavoriteProviderStatesTableFilterComposer,
        $$FavoriteProviderStatesTableOrderingComposer,
        $$FavoriteProviderStatesTableAnnotationComposer,
        $$FavoriteProviderStatesTableCreateCompanionBuilder,
        $$FavoriteProviderStatesTableUpdateCompanionBuilder,
        (
          FavoriteProviderState,
          BaseReferences<_$MeloDriftDatabase, $FavoriteProviderStatesTable,
              FavoriteProviderState>
        ),
        FavoriteProviderState,
        PrefetchHooks Function()>;
typedef $$StoredAudioCacheEntriesTableCreateCompanionBuilder
    = StoredAudioCacheEntriesCompanion Function({
  required String identityKey,
  required String providerId,
  required String trackId,
  required String quality,
  required String filePath,
  required int fileSize,
  required DateTime completedAt,
  required DateTime lastAccessedAt,
  Value<int> rowid,
});
typedef $$StoredAudioCacheEntriesTableUpdateCompanionBuilder
    = StoredAudioCacheEntriesCompanion Function({
  Value<String> identityKey,
  Value<String> providerId,
  Value<String> trackId,
  Value<String> quality,
  Value<String> filePath,
  Value<int> fileSize,
  Value<DateTime> completedAt,
  Value<DateTime> lastAccessedAt,
  Value<int> rowid,
});

class $$StoredAudioCacheEntriesTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredAudioCacheEntriesTable> {
  $$StoredAudioCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnFilters(column));
}

class $$StoredAudioCacheEntriesTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredAudioCacheEntriesTable> {
  $$StoredAudioCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$StoredAudioCacheEntriesTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredAudioCacheEntriesTable> {
  $$StoredAudioCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt, builder: (column) => column);
}

class $$StoredAudioCacheEntriesTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredAudioCacheEntriesTable,
    StoredAudioCacheEntry,
    $$StoredAudioCacheEntriesTableFilterComposer,
    $$StoredAudioCacheEntriesTableOrderingComposer,
    $$StoredAudioCacheEntriesTableAnnotationComposer,
    $$StoredAudioCacheEntriesTableCreateCompanionBuilder,
    $$StoredAudioCacheEntriesTableUpdateCompanionBuilder,
    (
      StoredAudioCacheEntry,
      BaseReferences<_$MeloDriftDatabase, $StoredAudioCacheEntriesTable,
          StoredAudioCacheEntry>
    ),
    StoredAudioCacheEntry,
    PrefetchHooks Function()> {
  $$StoredAudioCacheEntriesTableTableManager(
      _$MeloDriftDatabase db, $StoredAudioCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredAudioCacheEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredAudioCacheEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredAudioCacheEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> identityKey = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<String> quality = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<DateTime> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredAudioCacheEntriesCompanion(
            identityKey: identityKey,
            providerId: providerId,
            trackId: trackId,
            quality: quality,
            filePath: filePath,
            fileSize: fileSize,
            completedAt: completedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String identityKey,
            required String providerId,
            required String trackId,
            required String quality,
            required String filePath,
            required int fileSize,
            required DateTime completedAt,
            required DateTime lastAccessedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredAudioCacheEntriesCompanion.insert(
            identityKey: identityKey,
            providerId: providerId,
            trackId: trackId,
            quality: quality,
            filePath: filePath,
            fileSize: fileSize,
            completedAt: completedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredAudioCacheEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredAudioCacheEntriesTable,
        StoredAudioCacheEntry,
        $$StoredAudioCacheEntriesTableFilterComposer,
        $$StoredAudioCacheEntriesTableOrderingComposer,
        $$StoredAudioCacheEntriesTableAnnotationComposer,
        $$StoredAudioCacheEntriesTableCreateCompanionBuilder,
        $$StoredAudioCacheEntriesTableUpdateCompanionBuilder,
        (
          StoredAudioCacheEntry,
          BaseReferences<_$MeloDriftDatabase, $StoredAudioCacheEntriesTable,
              StoredAudioCacheEntry>
        ),
        StoredAudioCacheEntry,
        PrefetchHooks Function()>;
typedef $$AudioCacheSettingsTableCreateCompanionBuilder
    = AudioCacheSettingsCompanion Function({
  Value<int> id,
  required bool enabled,
  required bool wifiOnly,
  required int maxBytes,
});
typedef $$AudioCacheSettingsTableUpdateCompanionBuilder
    = AudioCacheSettingsCompanion Function({
  Value<int> id,
  Value<bool> enabled,
  Value<bool> wifiOnly,
  Value<int> maxBytes,
});

class $$AudioCacheSettingsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $AudioCacheSettingsTable> {
  $$AudioCacheSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxBytes => $composableBuilder(
      column: $table.maxBytes, builder: (column) => ColumnFilters(column));
}

class $$AudioCacheSettingsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $AudioCacheSettingsTable> {
  $$AudioCacheSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxBytes => $composableBuilder(
      column: $table.maxBytes, builder: (column) => ColumnOrderings(column));
}

class $$AudioCacheSettingsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $AudioCacheSettingsTable> {
  $$AudioCacheSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<int> get maxBytes =>
      $composableBuilder(column: $table.maxBytes, builder: (column) => column);
}

class $$AudioCacheSettingsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $AudioCacheSettingsTable,
    AudioCacheSetting,
    $$AudioCacheSettingsTableFilterComposer,
    $$AudioCacheSettingsTableOrderingComposer,
    $$AudioCacheSettingsTableAnnotationComposer,
    $$AudioCacheSettingsTableCreateCompanionBuilder,
    $$AudioCacheSettingsTableUpdateCompanionBuilder,
    (
      AudioCacheSetting,
      BaseReferences<_$MeloDriftDatabase, $AudioCacheSettingsTable,
          AudioCacheSetting>
    ),
    AudioCacheSetting,
    PrefetchHooks Function()> {
  $$AudioCacheSettingsTableTableManager(
      _$MeloDriftDatabase db, $AudioCacheSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCacheSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCacheSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCacheSettingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<bool> wifiOnly = const Value.absent(),
            Value<int> maxBytes = const Value.absent(),
          }) =>
              AudioCacheSettingsCompanion(
            id: id,
            enabled: enabled,
            wifiOnly: wifiOnly,
            maxBytes: maxBytes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required bool enabled,
            required bool wifiOnly,
            required int maxBytes,
          }) =>
              AudioCacheSettingsCompanion.insert(
            id: id,
            enabled: enabled,
            wifiOnly: wifiOnly,
            maxBytes: maxBytes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AudioCacheSettingsTableProcessedTableManager = ProcessedTableManager<
    _$MeloDriftDatabase,
    $AudioCacheSettingsTable,
    AudioCacheSetting,
    $$AudioCacheSettingsTableFilterComposer,
    $$AudioCacheSettingsTableOrderingComposer,
    $$AudioCacheSettingsTableAnnotationComposer,
    $$AudioCacheSettingsTableCreateCompanionBuilder,
    $$AudioCacheSettingsTableUpdateCompanionBuilder,
    (
      AudioCacheSetting,
      BaseReferences<_$MeloDriftDatabase, $AudioCacheSettingsTable,
          AudioCacheSetting>
    ),
    AudioCacheSetting,
    PrefetchHooks Function()>;

class $MeloDriftDatabaseManager {
  final _$MeloDriftDatabase _db;
  $MeloDriftDatabaseManager(this._db);
  $$MeloMetaRowsTableTableManager get meloMetaRows =>
      $$MeloMetaRowsTableTableManager(_db, _db.meloMetaRows);
  $$StoredPlaylistsTableTableManager get storedPlaylists =>
      $$StoredPlaylistsTableTableManager(_db, _db.storedPlaylists);
  $$StoredDownloadTasksTableTableManager get storedDownloadTasks =>
      $$StoredDownloadTasksTableTableManager(_db, _db.storedDownloadTasks);
  $$StoredLocalMediaItemsTableTableManager get storedLocalMediaItems =>
      $$StoredLocalMediaItemsTableTableManager(_db, _db.storedLocalMediaItems);
  $$StoredFavoriteOverridesTableTableManager get storedFavoriteOverrides =>
      $$StoredFavoriteOverridesTableTableManager(
          _db, _db.storedFavoriteOverrides);
  $$FavoriteProviderTracksTableTableManager get favoriteProviderTracks =>
      $$FavoriteProviderTracksTableTableManager(
          _db, _db.favoriteProviderTracks);
  $$FavoriteLikedAtLedgerRowsTableTableManager get favoriteLikedAtLedgerRows =>
      $$FavoriteLikedAtLedgerRowsTableTableManager(
          _db, _db.favoriteLikedAtLedgerRows);
  $$UnifiedFavoriteCacheRowsTableTableManager get unifiedFavoriteCacheRows =>
      $$UnifiedFavoriteCacheRowsTableTableManager(
          _db, _db.unifiedFavoriteCacheRows);
  $$FavoriteProviderStatesTableTableManager get favoriteProviderStates =>
      $$FavoriteProviderStatesTableTableManager(
          _db, _db.favoriteProviderStates);
  $$StoredAudioCacheEntriesTableTableManager get storedAudioCacheEntries =>
      $$StoredAudioCacheEntriesTableTableManager(
          _db, _db.storedAudioCacheEntries);
  $$AudioCacheSettingsTableTableManager get audioCacheSettings =>
      $$AudioCacheSettingsTableTableManager(_db, _db.audioCacheSettings);
}
