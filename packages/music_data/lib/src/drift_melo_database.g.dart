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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        meloMetaRows,
        storedPlaylists,
        storedDownloadTasks,
        storedLocalMediaItems,
        storedFavoriteOverrides
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
}
