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

class $StoredLocalLibraryRootsTable extends StoredLocalLibraryRoots
    with TableInfo<$StoredLocalLibraryRootsTable, StoredLocalLibraryRoot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalLibraryRootsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scanStateMeta =
      const VerificationMeta('scanState');
  @override
  late final GeneratedColumn<String> scanState = GeneratedColumn<String>(
      'scan_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastScannedAtMeta =
      const VerificationMeta('lastScannedAt');
  @override
  late final GeneratedColumn<DateTime> lastScannedAt =
      GeneratedColumn<DateTime>('last_scanned_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, path, displayName, scanState, lastScannedAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_library_roots';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalLibraryRoot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('scan_state')) {
      context.handle(_scanStateMeta,
          scanState.isAcceptableOrUnknown(data['scan_state']!, _scanStateMeta));
    } else if (isInserting) {
      context.missing(_scanStateMeta);
    }
    if (data.containsKey('last_scanned_at')) {
      context.handle(
          _lastScannedAtMeta,
          lastScannedAt.isAcceptableOrUnknown(
              data['last_scanned_at']!, _lastScannedAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredLocalLibraryRoot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalLibraryRoot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      scanState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scan_state'])!,
      lastScannedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_scanned_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $StoredLocalLibraryRootsTable createAlias(String alias) {
    return $StoredLocalLibraryRootsTable(attachedDatabase, alias);
  }
}

class StoredLocalLibraryRoot extends DataClass
    implements Insertable<StoredLocalLibraryRoot> {
  final String id;
  final String path;
  final String displayName;
  final String scanState;
  final DateTime? lastScannedAt;
  final String? lastError;
  const StoredLocalLibraryRoot(
      {required this.id,
      required this.path,
      required this.displayName,
      required this.scanState,
      this.lastScannedAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['display_name'] = Variable<String>(displayName);
    map['scan_state'] = Variable<String>(scanState);
    if (!nullToAbsent || lastScannedAt != null) {
      map['last_scanned_at'] = Variable<DateTime>(lastScannedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  StoredLocalLibraryRootsCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalLibraryRootsCompanion(
      id: Value(id),
      path: Value(path),
      displayName: Value(displayName),
      scanState: Value(scanState),
      lastScannedAt: lastScannedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScannedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory StoredLocalLibraryRoot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalLibraryRoot(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      displayName: serializer.fromJson<String>(json['displayName']),
      scanState: serializer.fromJson<String>(json['scanState']),
      lastScannedAt: serializer.fromJson<DateTime?>(json['lastScannedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'displayName': serializer.toJson<String>(displayName),
      'scanState': serializer.toJson<String>(scanState),
      'lastScannedAt': serializer.toJson<DateTime?>(lastScannedAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  StoredLocalLibraryRoot copyWith(
          {String? id,
          String? path,
          String? displayName,
          String? scanState,
          Value<DateTime?> lastScannedAt = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      StoredLocalLibraryRoot(
        id: id ?? this.id,
        path: path ?? this.path,
        displayName: displayName ?? this.displayName,
        scanState: scanState ?? this.scanState,
        lastScannedAt:
            lastScannedAt.present ? lastScannedAt.value : this.lastScannedAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  StoredLocalLibraryRoot copyWithCompanion(
      StoredLocalLibraryRootsCompanion data) {
    return StoredLocalLibraryRoot(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      scanState: data.scanState.present ? data.scanState.value : this.scanState,
      lastScannedAt: data.lastScannedAt.present
          ? data.lastScannedAt.value
          : this.lastScannedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryRoot(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('displayName: $displayName, ')
          ..write('scanState: $scanState, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, path, displayName, scanState, lastScannedAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalLibraryRoot &&
          other.id == this.id &&
          other.path == this.path &&
          other.displayName == this.displayName &&
          other.scanState == this.scanState &&
          other.lastScannedAt == this.lastScannedAt &&
          other.lastError == this.lastError);
}

class StoredLocalLibraryRootsCompanion
    extends UpdateCompanion<StoredLocalLibraryRoot> {
  final Value<String> id;
  final Value<String> path;
  final Value<String> displayName;
  final Value<String> scanState;
  final Value<DateTime?> lastScannedAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const StoredLocalLibraryRootsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.displayName = const Value.absent(),
    this.scanState = const Value.absent(),
    this.lastScannedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalLibraryRootsCompanion.insert({
    required String id,
    required String path,
    required String displayName,
    required String scanState,
    this.lastScannedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        path = Value(path),
        displayName = Value(displayName),
        scanState = Value(scanState);
  static Insertable<StoredLocalLibraryRoot> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? displayName,
    Expression<String>? scanState,
    Expression<DateTime>? lastScannedAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (displayName != null) 'display_name': displayName,
      if (scanState != null) 'scan_state': scanState,
      if (lastScannedAt != null) 'last_scanned_at': lastScannedAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalLibraryRootsCompanion copyWith(
      {Value<String>? id,
      Value<String>? path,
      Value<String>? displayName,
      Value<String>? scanState,
      Value<DateTime?>? lastScannedAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return StoredLocalLibraryRootsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      displayName: displayName ?? this.displayName,
      scanState: scanState ?? this.scanState,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (scanState.present) {
      map['scan_state'] = Variable<String>(scanState.value);
    }
    if (lastScannedAt.present) {
      map['last_scanned_at'] = Variable<DateTime>(lastScannedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryRootsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('displayName: $displayName, ')
          ..write('scanState: $scanState, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredLocalLibraryTracksTable extends StoredLocalLibraryTracks
    with TableInfo<$StoredLocalLibraryTracksTable, StoredLocalLibraryTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalLibraryTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rootIdMeta = const VerificationMeta('rootId');
  @override
  late final GeneratedColumn<String> rootId = GeneratedColumn<String>(
      'root_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _fingerprintMeta =
      const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
      'fingerprint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistsJsonMeta =
      const VerificationMeta('artistsJson');
  @override
  late final GeneratedColumn<String> artistsJson = GeneratedColumn<String>(
      'artists_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genresJsonMeta =
      const VerificationMeta('genresJson');
  @override
  late final GeneratedColumn<String> genresJson = GeneratedColumn<String>(
      'genres_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _embeddedAlbumArtistMeta =
      const VerificationMeta('embeddedAlbumArtist');
  @override
  late final GeneratedColumn<String> embeddedAlbumArtist =
      GeneratedColumn<String>('embedded_album_artist', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumArtistMeta =
      const VerificationMeta('albumArtist');
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
      'album_artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumArtistSourceMeta =
      const VerificationMeta('albumArtistSource');
  @override
  late final GeneratedColumn<String> albumArtistSource =
      GeneratedColumn<String>('album_artist_source', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('unresolved'));
  static const VerificationMeta _albumEditionKeyMeta =
      const VerificationMeta('albumEditionKey');
  @override
  late final GeneratedColumn<String> albumEditionKey = GeneratedColumn<String>(
      'album_edition_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isrcMeta = const VerificationMeta('isrc');
  @override
  late final GeneratedColumn<String> isrc = GeneratedColumn<String>(
      'isrc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _bitRateMeta =
      const VerificationMeta('bitRate');
  @override
  late final GeneratedColumn<int> bitRate = GeneratedColumn<int>(
      'bit_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sampleRateMeta =
      const VerificationMeta('sampleRate');
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
      'sample_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bitDepthMeta =
      const VerificationMeta('bitDepth');
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
      'bit_depth', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _normalizedTitleMeta =
      const VerificationMeta('normalizedTitle');
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
      'normalized_title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _normalizedArtistsMeta =
      const VerificationMeta('normalizedArtists');
  @override
  late final GeneratedColumn<String> normalizedArtists =
      GeneratedColumn<String>('normalized_artists', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _normalizedAlbumMeta =
      const VerificationMeta('normalizedAlbum');
  @override
  late final GeneratedColumn<String> normalizedAlbum = GeneratedColumn<String>(
      'normalized_album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trackNumberMeta =
      const VerificationMeta('trackNumber');
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
      'track_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _discNumberMeta =
      const VerificationMeta('discNumber');
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
      'disc_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
      'lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artworkPathMeta =
      const VerificationMeta('artworkPath');
  @override
  late final GeneratedColumn<String> artworkPath = GeneratedColumn<String>(
      'artwork_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isAvailableMeta =
      const VerificationMeta('isAvailable');
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
      'is_available', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_available" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rootId,
        filePath,
        relativePath,
        fileSize,
        modifiedAt,
        fingerprint,
        title,
        artistsJson,
        durationMs,
        format,
        album,
        genre,
        genresJson,
        embeddedAlbumArtist,
        albumArtist,
        albumArtistSource,
        albumEditionKey,
        isrc,
        addedAt,
        bitRate,
        sampleRate,
        bitDepth,
        normalizedTitle,
        normalizedArtists,
        normalizedAlbum,
        year,
        trackNumber,
        discNumber,
        lyrics,
        artworkPath,
        isAvailable
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_library_tracks';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalLibraryTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('root_id')) {
      context.handle(_rootIdMeta,
          rootId.isAcceptableOrUnknown(data['root_id']!, _rootIdMeta));
    } else if (isInserting) {
      context.missing(_rootIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
          _fingerprintMeta,
          fingerprint.isAcceptableOrUnknown(
              data['fingerprint']!, _fingerprintMeta));
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists_json')) {
      context.handle(
          _artistsJsonMeta,
          artistsJson.isAcceptableOrUnknown(
              data['artists_json']!, _artistsJsonMeta));
    } else if (isInserting) {
      context.missing(_artistsJsonMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('genres_json')) {
      context.handle(
          _genresJsonMeta,
          genresJson.isAcceptableOrUnknown(
              data['genres_json']!, _genresJsonMeta));
    }
    if (data.containsKey('embedded_album_artist')) {
      context.handle(
          _embeddedAlbumArtistMeta,
          embeddedAlbumArtist.isAcceptableOrUnknown(
              data['embedded_album_artist']!, _embeddedAlbumArtistMeta));
    }
    if (data.containsKey('album_artist')) {
      context.handle(
          _albumArtistMeta,
          albumArtist.isAcceptableOrUnknown(
              data['album_artist']!, _albumArtistMeta));
    }
    if (data.containsKey('album_artist_source')) {
      context.handle(
          _albumArtistSourceMeta,
          albumArtistSource.isAcceptableOrUnknown(
              data['album_artist_source']!, _albumArtistSourceMeta));
    }
    if (data.containsKey('album_edition_key')) {
      context.handle(
          _albumEditionKeyMeta,
          albumEditionKey.isAcceptableOrUnknown(
              data['album_edition_key']!, _albumEditionKeyMeta));
    }
    if (data.containsKey('isrc')) {
      context.handle(
          _isrcMeta, isrc.isAcceptableOrUnknown(data['isrc']!, _isrcMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    }
    if (data.containsKey('bit_rate')) {
      context.handle(_bitRateMeta,
          bitRate.isAcceptableOrUnknown(data['bit_rate']!, _bitRateMeta));
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
          _sampleRateMeta,
          sampleRate.isAcceptableOrUnknown(
              data['sample_rate']!, _sampleRateMeta));
    }
    if (data.containsKey('bit_depth')) {
      context.handle(_bitDepthMeta,
          bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta));
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
          _normalizedTitleMeta,
          normalizedTitle.isAcceptableOrUnknown(
              data['normalized_title']!, _normalizedTitleMeta));
    }
    if (data.containsKey('normalized_artists')) {
      context.handle(
          _normalizedArtistsMeta,
          normalizedArtists.isAcceptableOrUnknown(
              data['normalized_artists']!, _normalizedArtistsMeta));
    }
    if (data.containsKey('normalized_album')) {
      context.handle(
          _normalizedAlbumMeta,
          normalizedAlbum.isAcceptableOrUnknown(
              data['normalized_album']!, _normalizedAlbumMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('track_number')) {
      context.handle(
          _trackNumberMeta,
          trackNumber.isAcceptableOrUnknown(
              data['track_number']!, _trackNumberMeta));
    }
    if (data.containsKey('disc_number')) {
      context.handle(
          _discNumberMeta,
          discNumber.isAcceptableOrUnknown(
              data['disc_number']!, _discNumberMeta));
    }
    if (data.containsKey('lyrics')) {
      context.handle(_lyricsMeta,
          lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta));
    }
    if (data.containsKey('artwork_path')) {
      context.handle(
          _artworkPathMeta,
          artworkPath.isAcceptableOrUnknown(
              data['artwork_path']!, _artworkPathMeta));
    }
    if (data.containsKey('is_available')) {
      context.handle(
          _isAvailableMeta,
          isAvailable.isAcceptableOrUnknown(
              data['is_available']!, _isAvailableMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredLocalLibraryTrack map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalLibraryTrack(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rootId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}root_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      fingerprint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fingerprint'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artistsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artists_json'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album']),
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      genresJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genres_json'])!,
      embeddedAlbumArtist: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}embedded_album_artist']),
      albumArtist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_artist']),
      albumArtistSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}album_artist_source'])!,
      albumEditionKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}album_edition_key']),
      isrc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isrc']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at']),
      bitRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bit_rate']),
      sampleRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sample_rate']),
      bitDepth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bit_depth']),
      normalizedTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_title'])!,
      normalizedArtists: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_artists'])!,
      normalizedAlbum: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_album'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      trackNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}track_number']),
      discNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}disc_number']),
      lyrics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics']),
      artworkPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artwork_path']),
      isAvailable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_available'])!,
    );
  }

  @override
  $StoredLocalLibraryTracksTable createAlias(String alias) {
    return $StoredLocalLibraryTracksTable(attachedDatabase, alias);
  }
}

class StoredLocalLibraryTrack extends DataClass
    implements Insertable<StoredLocalLibraryTrack> {
  final String id;
  final String rootId;
  final String filePath;
  final String relativePath;
  final int fileSize;
  final DateTime modifiedAt;
  final String fingerprint;
  final String title;
  final String artistsJson;
  final int durationMs;
  final String format;
  final String? album;
  final String? genre;
  final String genresJson;
  final String? embeddedAlbumArtist;
  final String? albumArtist;
  final String albumArtistSource;
  final String? albumEditionKey;
  final String? isrc;
  final DateTime? addedAt;
  final int? bitRate;
  final int? sampleRate;
  final int? bitDepth;
  final String normalizedTitle;
  final String normalizedArtists;
  final String normalizedAlbum;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? lyrics;
  final String? artworkPath;
  final bool isAvailable;
  const StoredLocalLibraryTrack(
      {required this.id,
      required this.rootId,
      required this.filePath,
      required this.relativePath,
      required this.fileSize,
      required this.modifiedAt,
      required this.fingerprint,
      required this.title,
      required this.artistsJson,
      required this.durationMs,
      required this.format,
      this.album,
      this.genre,
      required this.genresJson,
      this.embeddedAlbumArtist,
      this.albumArtist,
      required this.albumArtistSource,
      this.albumEditionKey,
      this.isrc,
      this.addedAt,
      this.bitRate,
      this.sampleRate,
      this.bitDepth,
      required this.normalizedTitle,
      required this.normalizedArtists,
      required this.normalizedAlbum,
      this.year,
      this.trackNumber,
      this.discNumber,
      this.lyrics,
      this.artworkPath,
      required this.isAvailable});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['root_id'] = Variable<String>(rootId);
    map['file_path'] = Variable<String>(filePath);
    map['relative_path'] = Variable<String>(relativePath);
    map['file_size'] = Variable<int>(fileSize);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['title'] = Variable<String>(title);
    map['artists_json'] = Variable<String>(artistsJson);
    map['duration_ms'] = Variable<int>(durationMs);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['genres_json'] = Variable<String>(genresJson);
    if (!nullToAbsent || embeddedAlbumArtist != null) {
      map['embedded_album_artist'] = Variable<String>(embeddedAlbumArtist);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    map['album_artist_source'] = Variable<String>(albumArtistSource);
    if (!nullToAbsent || albumEditionKey != null) {
      map['album_edition_key'] = Variable<String>(albumEditionKey);
    }
    if (!nullToAbsent || isrc != null) {
      map['isrc'] = Variable<String>(isrc);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    if (!nullToAbsent || bitRate != null) {
      map['bit_rate'] = Variable<int>(bitRate);
    }
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = Variable<int>(sampleRate);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    map['normalized_title'] = Variable<String>(normalizedTitle);
    map['normalized_artists'] = Variable<String>(normalizedArtists);
    map['normalized_album'] = Variable<String>(normalizedAlbum);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    if (!nullToAbsent || artworkPath != null) {
      map['artwork_path'] = Variable<String>(artworkPath);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    return map;
  }

  StoredLocalLibraryTracksCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalLibraryTracksCompanion(
      id: Value(id),
      rootId: Value(rootId),
      filePath: Value(filePath),
      relativePath: Value(relativePath),
      fileSize: Value(fileSize),
      modifiedAt: Value(modifiedAt),
      fingerprint: Value(fingerprint),
      title: Value(title),
      artistsJson: Value(artistsJson),
      durationMs: Value(durationMs),
      format: Value(format),
      album:
          album == null && nullToAbsent ? const Value.absent() : Value(album),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      genresJson: Value(genresJson),
      embeddedAlbumArtist: embeddedAlbumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddedAlbumArtist),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      albumArtistSource: Value(albumArtistSource),
      albumEditionKey: albumEditionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(albumEditionKey),
      isrc: isrc == null && nullToAbsent ? const Value.absent() : Value(isrc),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      bitRate: bitRate == null && nullToAbsent
          ? const Value.absent()
          : Value(bitRate),
      sampleRate: sampleRate == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRate),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      normalizedTitle: Value(normalizedTitle),
      normalizedArtists: Value(normalizedArtists),
      normalizedAlbum: Value(normalizedAlbum),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      lyrics:
          lyrics == null && nullToAbsent ? const Value.absent() : Value(lyrics),
      artworkPath: artworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkPath),
      isAvailable: Value(isAvailable),
    );
  }

  factory StoredLocalLibraryTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalLibraryTrack(
      id: serializer.fromJson<String>(json['id']),
      rootId: serializer.fromJson<String>(json['rootId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      title: serializer.fromJson<String>(json['title']),
      artistsJson: serializer.fromJson<String>(json['artistsJson']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      format: serializer.fromJson<String>(json['format']),
      album: serializer.fromJson<String?>(json['album']),
      genre: serializer.fromJson<String?>(json['genre']),
      genresJson: serializer.fromJson<String>(json['genresJson']),
      embeddedAlbumArtist:
          serializer.fromJson<String?>(json['embeddedAlbumArtist']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      albumArtistSource: serializer.fromJson<String>(json['albumArtistSource']),
      albumEditionKey: serializer.fromJson<String?>(json['albumEditionKey']),
      isrc: serializer.fromJson<String?>(json['isrc']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      bitRate: serializer.fromJson<int?>(json['bitRate']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      normalizedArtists: serializer.fromJson<String>(json['normalizedArtists']),
      normalizedAlbum: serializer.fromJson<String>(json['normalizedAlbum']),
      year: serializer.fromJson<int?>(json['year']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      artworkPath: serializer.fromJson<String?>(json['artworkPath']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rootId': serializer.toJson<String>(rootId),
      'filePath': serializer.toJson<String>(filePath),
      'relativePath': serializer.toJson<String>(relativePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'title': serializer.toJson<String>(title),
      'artistsJson': serializer.toJson<String>(artistsJson),
      'durationMs': serializer.toJson<int>(durationMs),
      'format': serializer.toJson<String>(format),
      'album': serializer.toJson<String?>(album),
      'genre': serializer.toJson<String?>(genre),
      'genresJson': serializer.toJson<String>(genresJson),
      'embeddedAlbumArtist': serializer.toJson<String?>(embeddedAlbumArtist),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'albumArtistSource': serializer.toJson<String>(albumArtistSource),
      'albumEditionKey': serializer.toJson<String?>(albumEditionKey),
      'isrc': serializer.toJson<String?>(isrc),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'bitRate': serializer.toJson<int?>(bitRate),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'normalizedArtists': serializer.toJson<String>(normalizedArtists),
      'normalizedAlbum': serializer.toJson<String>(normalizedAlbum),
      'year': serializer.toJson<int?>(year),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'lyrics': serializer.toJson<String?>(lyrics),
      'artworkPath': serializer.toJson<String?>(artworkPath),
      'isAvailable': serializer.toJson<bool>(isAvailable),
    };
  }

  StoredLocalLibraryTrack copyWith(
          {String? id,
          String? rootId,
          String? filePath,
          String? relativePath,
          int? fileSize,
          DateTime? modifiedAt,
          String? fingerprint,
          String? title,
          String? artistsJson,
          int? durationMs,
          String? format,
          Value<String?> album = const Value.absent(),
          Value<String?> genre = const Value.absent(),
          String? genresJson,
          Value<String?> embeddedAlbumArtist = const Value.absent(),
          Value<String?> albumArtist = const Value.absent(),
          String? albumArtistSource,
          Value<String?> albumEditionKey = const Value.absent(),
          Value<String?> isrc = const Value.absent(),
          Value<DateTime?> addedAt = const Value.absent(),
          Value<int?> bitRate = const Value.absent(),
          Value<int?> sampleRate = const Value.absent(),
          Value<int?> bitDepth = const Value.absent(),
          String? normalizedTitle,
          String? normalizedArtists,
          String? normalizedAlbum,
          Value<int?> year = const Value.absent(),
          Value<int?> trackNumber = const Value.absent(),
          Value<int?> discNumber = const Value.absent(),
          Value<String?> lyrics = const Value.absent(),
          Value<String?> artworkPath = const Value.absent(),
          bool? isAvailable}) =>
      StoredLocalLibraryTrack(
        id: id ?? this.id,
        rootId: rootId ?? this.rootId,
        filePath: filePath ?? this.filePath,
        relativePath: relativePath ?? this.relativePath,
        fileSize: fileSize ?? this.fileSize,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        fingerprint: fingerprint ?? this.fingerprint,
        title: title ?? this.title,
        artistsJson: artistsJson ?? this.artistsJson,
        durationMs: durationMs ?? this.durationMs,
        format: format ?? this.format,
        album: album.present ? album.value : this.album,
        genre: genre.present ? genre.value : this.genre,
        genresJson: genresJson ?? this.genresJson,
        embeddedAlbumArtist: embeddedAlbumArtist.present
            ? embeddedAlbumArtist.value
            : this.embeddedAlbumArtist,
        albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
        albumArtistSource: albumArtistSource ?? this.albumArtistSource,
        albumEditionKey: albumEditionKey.present
            ? albumEditionKey.value
            : this.albumEditionKey,
        isrc: isrc.present ? isrc.value : this.isrc,
        addedAt: addedAt.present ? addedAt.value : this.addedAt,
        bitRate: bitRate.present ? bitRate.value : this.bitRate,
        sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
        bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
        normalizedTitle: normalizedTitle ?? this.normalizedTitle,
        normalizedArtists: normalizedArtists ?? this.normalizedArtists,
        normalizedAlbum: normalizedAlbum ?? this.normalizedAlbum,
        year: year.present ? year.value : this.year,
        trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
        discNumber: discNumber.present ? discNumber.value : this.discNumber,
        lyrics: lyrics.present ? lyrics.value : this.lyrics,
        artworkPath: artworkPath.present ? artworkPath.value : this.artworkPath,
        isAvailable: isAvailable ?? this.isAvailable,
      );
  StoredLocalLibraryTrack copyWithCompanion(
      StoredLocalLibraryTracksCompanion data) {
    return StoredLocalLibraryTrack(
      id: data.id.present ? data.id.value : this.id,
      rootId: data.rootId.present ? data.rootId.value : this.rootId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      fingerprint:
          data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      title: data.title.present ? data.title.value : this.title,
      artistsJson:
          data.artistsJson.present ? data.artistsJson.value : this.artistsJson,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      format: data.format.present ? data.format.value : this.format,
      album: data.album.present ? data.album.value : this.album,
      genre: data.genre.present ? data.genre.value : this.genre,
      genresJson:
          data.genresJson.present ? data.genresJson.value : this.genresJson,
      embeddedAlbumArtist: data.embeddedAlbumArtist.present
          ? data.embeddedAlbumArtist.value
          : this.embeddedAlbumArtist,
      albumArtist:
          data.albumArtist.present ? data.albumArtist.value : this.albumArtist,
      albumArtistSource: data.albumArtistSource.present
          ? data.albumArtistSource.value
          : this.albumArtistSource,
      albumEditionKey: data.albumEditionKey.present
          ? data.albumEditionKey.value
          : this.albumEditionKey,
      isrc: data.isrc.present ? data.isrc.value : this.isrc,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      bitRate: data.bitRate.present ? data.bitRate.value : this.bitRate,
      sampleRate:
          data.sampleRate.present ? data.sampleRate.value : this.sampleRate,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      normalizedArtists: data.normalizedArtists.present
          ? data.normalizedArtists.value
          : this.normalizedArtists,
      normalizedAlbum: data.normalizedAlbum.present
          ? data.normalizedAlbum.value
          : this.normalizedAlbum,
      year: data.year.present ? data.year.value : this.year,
      trackNumber:
          data.trackNumber.present ? data.trackNumber.value : this.trackNumber,
      discNumber:
          data.discNumber.present ? data.discNumber.value : this.discNumber,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      artworkPath:
          data.artworkPath.present ? data.artworkPath.value : this.artworkPath,
      isAvailable:
          data.isAvailable.present ? data.isAvailable.value : this.isAvailable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryTrack(')
          ..write('id: $id, ')
          ..write('rootId: $rootId, ')
          ..write('filePath: $filePath, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('genresJson: $genresJson, ')
          ..write('embeddedAlbumArtist: $embeddedAlbumArtist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('albumArtistSource: $albumArtistSource, ')
          ..write('albumEditionKey: $albumEditionKey, ')
          ..write('isrc: $isrc, ')
          ..write('addedAt: $addedAt, ')
          ..write('bitRate: $bitRate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('normalizedArtists: $normalizedArtists, ')
          ..write('normalizedAlbum: $normalizedAlbum, ')
          ..write('year: $year, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('lyrics: $lyrics, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('isAvailable: $isAvailable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        rootId,
        filePath,
        relativePath,
        fileSize,
        modifiedAt,
        fingerprint,
        title,
        artistsJson,
        durationMs,
        format,
        album,
        genre,
        genresJson,
        embeddedAlbumArtist,
        albumArtist,
        albumArtistSource,
        albumEditionKey,
        isrc,
        addedAt,
        bitRate,
        sampleRate,
        bitDepth,
        normalizedTitle,
        normalizedArtists,
        normalizedAlbum,
        year,
        trackNumber,
        discNumber,
        lyrics,
        artworkPath,
        isAvailable
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalLibraryTrack &&
          other.id == this.id &&
          other.rootId == this.rootId &&
          other.filePath == this.filePath &&
          other.relativePath == this.relativePath &&
          other.fileSize == this.fileSize &&
          other.modifiedAt == this.modifiedAt &&
          other.fingerprint == this.fingerprint &&
          other.title == this.title &&
          other.artistsJson == this.artistsJson &&
          other.durationMs == this.durationMs &&
          other.format == this.format &&
          other.album == this.album &&
          other.genre == this.genre &&
          other.genresJson == this.genresJson &&
          other.embeddedAlbumArtist == this.embeddedAlbumArtist &&
          other.albumArtist == this.albumArtist &&
          other.albumArtistSource == this.albumArtistSource &&
          other.albumEditionKey == this.albumEditionKey &&
          other.isrc == this.isrc &&
          other.addedAt == this.addedAt &&
          other.bitRate == this.bitRate &&
          other.sampleRate == this.sampleRate &&
          other.bitDepth == this.bitDepth &&
          other.normalizedTitle == this.normalizedTitle &&
          other.normalizedArtists == this.normalizedArtists &&
          other.normalizedAlbum == this.normalizedAlbum &&
          other.year == this.year &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.lyrics == this.lyrics &&
          other.artworkPath == this.artworkPath &&
          other.isAvailable == this.isAvailable);
}

class StoredLocalLibraryTracksCompanion
    extends UpdateCompanion<StoredLocalLibraryTrack> {
  final Value<String> id;
  final Value<String> rootId;
  final Value<String> filePath;
  final Value<String> relativePath;
  final Value<int> fileSize;
  final Value<DateTime> modifiedAt;
  final Value<String> fingerprint;
  final Value<String> title;
  final Value<String> artistsJson;
  final Value<int> durationMs;
  final Value<String> format;
  final Value<String?> album;
  final Value<String?> genre;
  final Value<String> genresJson;
  final Value<String?> embeddedAlbumArtist;
  final Value<String?> albumArtist;
  final Value<String> albumArtistSource;
  final Value<String?> albumEditionKey;
  final Value<String?> isrc;
  final Value<DateTime?> addedAt;
  final Value<int?> bitRate;
  final Value<int?> sampleRate;
  final Value<int?> bitDepth;
  final Value<String> normalizedTitle;
  final Value<String> normalizedArtists;
  final Value<String> normalizedAlbum;
  final Value<int?> year;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<String?> lyrics;
  final Value<String?> artworkPath;
  final Value<bool> isAvailable;
  final Value<int> rowid;
  const StoredLocalLibraryTracksCompanion({
    this.id = const Value.absent(),
    this.rootId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.title = const Value.absent(),
    this.artistsJson = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.format = const Value.absent(),
    this.album = const Value.absent(),
    this.genre = const Value.absent(),
    this.genresJson = const Value.absent(),
    this.embeddedAlbumArtist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.albumArtistSource = const Value.absent(),
    this.albumEditionKey = const Value.absent(),
    this.isrc = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.bitRate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.normalizedArtists = const Value.absent(),
    this.normalizedAlbum = const Value.absent(),
    this.year = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalLibraryTracksCompanion.insert({
    required String id,
    required String rootId,
    required String filePath,
    required String relativePath,
    required int fileSize,
    required DateTime modifiedAt,
    required String fingerprint,
    required String title,
    required String artistsJson,
    required int durationMs,
    required String format,
    this.album = const Value.absent(),
    this.genre = const Value.absent(),
    this.genresJson = const Value.absent(),
    this.embeddedAlbumArtist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.albumArtistSource = const Value.absent(),
    this.albumEditionKey = const Value.absent(),
    this.isrc = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.bitRate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.normalizedArtists = const Value.absent(),
    this.normalizedAlbum = const Value.absent(),
    this.year = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rootId = Value(rootId),
        filePath = Value(filePath),
        relativePath = Value(relativePath),
        fileSize = Value(fileSize),
        modifiedAt = Value(modifiedAt),
        fingerprint = Value(fingerprint),
        title = Value(title),
        artistsJson = Value(artistsJson),
        durationMs = Value(durationMs),
        format = Value(format);
  static Insertable<StoredLocalLibraryTrack> custom({
    Expression<String>? id,
    Expression<String>? rootId,
    Expression<String>? filePath,
    Expression<String>? relativePath,
    Expression<int>? fileSize,
    Expression<DateTime>? modifiedAt,
    Expression<String>? fingerprint,
    Expression<String>? title,
    Expression<String>? artistsJson,
    Expression<int>? durationMs,
    Expression<String>? format,
    Expression<String>? album,
    Expression<String>? genre,
    Expression<String>? genresJson,
    Expression<String>? embeddedAlbumArtist,
    Expression<String>? albumArtist,
    Expression<String>? albumArtistSource,
    Expression<String>? albumEditionKey,
    Expression<String>? isrc,
    Expression<DateTime>? addedAt,
    Expression<int>? bitRate,
    Expression<int>? sampleRate,
    Expression<int>? bitDepth,
    Expression<String>? normalizedTitle,
    Expression<String>? normalizedArtists,
    Expression<String>? normalizedAlbum,
    Expression<int>? year,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<String>? lyrics,
    Expression<String>? artworkPath,
    Expression<bool>? isAvailable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rootId != null) 'root_id': rootId,
      if (filePath != null) 'file_path': filePath,
      if (relativePath != null) 'relative_path': relativePath,
      if (fileSize != null) 'file_size': fileSize,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (title != null) 'title': title,
      if (artistsJson != null) 'artists_json': artistsJson,
      if (durationMs != null) 'duration_ms': durationMs,
      if (format != null) 'format': format,
      if (album != null) 'album': album,
      if (genre != null) 'genre': genre,
      if (genresJson != null) 'genres_json': genresJson,
      if (embeddedAlbumArtist != null)
        'embedded_album_artist': embeddedAlbumArtist,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (albumArtistSource != null) 'album_artist_source': albumArtistSource,
      if (albumEditionKey != null) 'album_edition_key': albumEditionKey,
      if (isrc != null) 'isrc': isrc,
      if (addedAt != null) 'added_at': addedAt,
      if (bitRate != null) 'bit_rate': bitRate,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (normalizedArtists != null) 'normalized_artists': normalizedArtists,
      if (normalizedAlbum != null) 'normalized_album': normalizedAlbum,
      if (year != null) 'year': year,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (lyrics != null) 'lyrics': lyrics,
      if (artworkPath != null) 'artwork_path': artworkPath,
      if (isAvailable != null) 'is_available': isAvailable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalLibraryTracksCompanion copyWith(
      {Value<String>? id,
      Value<String>? rootId,
      Value<String>? filePath,
      Value<String>? relativePath,
      Value<int>? fileSize,
      Value<DateTime>? modifiedAt,
      Value<String>? fingerprint,
      Value<String>? title,
      Value<String>? artistsJson,
      Value<int>? durationMs,
      Value<String>? format,
      Value<String?>? album,
      Value<String?>? genre,
      Value<String>? genresJson,
      Value<String?>? embeddedAlbumArtist,
      Value<String?>? albumArtist,
      Value<String>? albumArtistSource,
      Value<String?>? albumEditionKey,
      Value<String?>? isrc,
      Value<DateTime?>? addedAt,
      Value<int?>? bitRate,
      Value<int?>? sampleRate,
      Value<int?>? bitDepth,
      Value<String>? normalizedTitle,
      Value<String>? normalizedArtists,
      Value<String>? normalizedAlbum,
      Value<int?>? year,
      Value<int?>? trackNumber,
      Value<int?>? discNumber,
      Value<String?>? lyrics,
      Value<String?>? artworkPath,
      Value<bool>? isAvailable,
      Value<int>? rowid}) {
    return StoredLocalLibraryTracksCompanion(
      id: id ?? this.id,
      rootId: rootId ?? this.rootId,
      filePath: filePath ?? this.filePath,
      relativePath: relativePath ?? this.relativePath,
      fileSize: fileSize ?? this.fileSize,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      fingerprint: fingerprint ?? this.fingerprint,
      title: title ?? this.title,
      artistsJson: artistsJson ?? this.artistsJson,
      durationMs: durationMs ?? this.durationMs,
      format: format ?? this.format,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      genresJson: genresJson ?? this.genresJson,
      embeddedAlbumArtist: embeddedAlbumArtist ?? this.embeddedAlbumArtist,
      albumArtist: albumArtist ?? this.albumArtist,
      albumArtistSource: albumArtistSource ?? this.albumArtistSource,
      albumEditionKey: albumEditionKey ?? this.albumEditionKey,
      isrc: isrc ?? this.isrc,
      addedAt: addedAt ?? this.addedAt,
      bitRate: bitRate ?? this.bitRate,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      normalizedArtists: normalizedArtists ?? this.normalizedArtists,
      normalizedAlbum: normalizedAlbum ?? this.normalizedAlbum,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      lyrics: lyrics ?? this.lyrics,
      artworkPath: artworkPath ?? this.artworkPath,
      isAvailable: isAvailable ?? this.isAvailable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rootId.present) {
      map['root_id'] = Variable<String>(rootId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistsJson.present) {
      map['artists_json'] = Variable<String>(artistsJson.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (genresJson.present) {
      map['genres_json'] = Variable<String>(genresJson.value);
    }
    if (embeddedAlbumArtist.present) {
      map['embedded_album_artist'] =
          Variable<String>(embeddedAlbumArtist.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (albumArtistSource.present) {
      map['album_artist_source'] = Variable<String>(albumArtistSource.value);
    }
    if (albumEditionKey.present) {
      map['album_edition_key'] = Variable<String>(albumEditionKey.value);
    }
    if (isrc.present) {
      map['isrc'] = Variable<String>(isrc.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (bitRate.present) {
      map['bit_rate'] = Variable<int>(bitRate.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (normalizedArtists.present) {
      map['normalized_artists'] = Variable<String>(normalizedArtists.value);
    }
    if (normalizedAlbum.present) {
      map['normalized_album'] = Variable<String>(normalizedAlbum.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (artworkPath.present) {
      map['artwork_path'] = Variable<String>(artworkPath.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryTracksCompanion(')
          ..write('id: $id, ')
          ..write('rootId: $rootId, ')
          ..write('filePath: $filePath, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('genresJson: $genresJson, ')
          ..write('embeddedAlbumArtist: $embeddedAlbumArtist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('albumArtistSource: $albumArtistSource, ')
          ..write('albumEditionKey: $albumEditionKey, ')
          ..write('isrc: $isrc, ')
          ..write('addedAt: $addedAt, ')
          ..write('bitRate: $bitRate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('normalizedArtists: $normalizedArtists, ')
          ..write('normalizedAlbum: $normalizedAlbum, ')
          ..write('year: $year, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('lyrics: $lyrics, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredLocalLibraryFavoritesTable extends StoredLocalLibraryFavorites
    with
        TableInfo<$StoredLocalLibraryFavoritesTable,
            StoredLocalLibraryFavorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalLibraryFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _likedAtMeta =
      const VerificationMeta('likedAt');
  @override
  late final GeneratedColumn<DateTime> likedAt = GeneratedColumn<DateTime>(
      'liked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [trackId, likedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_library_favorites';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalLibraryFavorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('liked_at')) {
      context.handle(_likedAtMeta,
          likedAt.isAcceptableOrUnknown(data['liked_at']!, _likedAtMeta));
    } else if (isInserting) {
      context.missing(_likedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  StoredLocalLibraryFavorite map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalLibraryFavorite(
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      likedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}liked_at'])!,
    );
  }

  @override
  $StoredLocalLibraryFavoritesTable createAlias(String alias) {
    return $StoredLocalLibraryFavoritesTable(attachedDatabase, alias);
  }
}

class StoredLocalLibraryFavorite extends DataClass
    implements Insertable<StoredLocalLibraryFavorite> {
  final String trackId;
  final DateTime likedAt;
  const StoredLocalLibraryFavorite(
      {required this.trackId, required this.likedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['liked_at'] = Variable<DateTime>(likedAt);
    return map;
  }

  StoredLocalLibraryFavoritesCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalLibraryFavoritesCompanion(
      trackId: Value(trackId),
      likedAt: Value(likedAt),
    );
  }

  factory StoredLocalLibraryFavorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalLibraryFavorite(
      trackId: serializer.fromJson<String>(json['trackId']),
      likedAt: serializer.fromJson<DateTime>(json['likedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'likedAt': serializer.toJson<DateTime>(likedAt),
    };
  }

  StoredLocalLibraryFavorite copyWith({String? trackId, DateTime? likedAt}) =>
      StoredLocalLibraryFavorite(
        trackId: trackId ?? this.trackId,
        likedAt: likedAt ?? this.likedAt,
      );
  StoredLocalLibraryFavorite copyWithCompanion(
      StoredLocalLibraryFavoritesCompanion data) {
    return StoredLocalLibraryFavorite(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      likedAt: data.likedAt.present ? data.likedAt.value : this.likedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryFavorite(')
          ..write('trackId: $trackId, ')
          ..write('likedAt: $likedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, likedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalLibraryFavorite &&
          other.trackId == this.trackId &&
          other.likedAt == this.likedAt);
}

class StoredLocalLibraryFavoritesCompanion
    extends UpdateCompanion<StoredLocalLibraryFavorite> {
  final Value<String> trackId;
  final Value<DateTime> likedAt;
  final Value<int> rowid;
  const StoredLocalLibraryFavoritesCompanion({
    this.trackId = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalLibraryFavoritesCompanion.insert({
    required String trackId,
    required DateTime likedAt,
    this.rowid = const Value.absent(),
  })  : trackId = Value(trackId),
        likedAt = Value(likedAt);
  static Insertable<StoredLocalLibraryFavorite> custom({
    Expression<String>? trackId,
    Expression<DateTime>? likedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (likedAt != null) 'liked_at': likedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalLibraryFavoritesCompanion copyWith(
      {Value<String>? trackId, Value<DateTime>? likedAt, Value<int>? rowid}) {
    return StoredLocalLibraryFavoritesCompanion(
      trackId: trackId ?? this.trackId,
      likedAt: likedAt ?? this.likedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (likedAt.present) {
      map['liked_at'] = Variable<DateTime>(likedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalLibraryFavoritesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('likedAt: $likedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredLocalArtistMetadataTable extends StoredLocalArtistMetadata
    with
        TableInfo<$StoredLocalArtistMetadataTable,
            StoredLocalArtistMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalArtistMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artistKeyMeta =
      const VerificationMeta('artistKey');
  @override
  late final GeneratedColumn<String> artistKey = GeneratedColumn<String>(
      'artist_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceProviderIdMeta =
      const VerificationMeta('sourceProviderId');
  @override
  late final GeneratedColumn<String> sourceProviderId = GeneratedColumn<String>(
      'source_provider_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remoteArtistIdMeta =
      const VerificationMeta('remoteArtistId');
  @override
  late final GeneratedColumn<String> remoteArtistId = GeneratedColumn<String>(
      'remote_artist_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remoteNameMeta =
      const VerificationMeta('remoteName');
  @override
  late final GeneratedColumn<String> remoteName = GeneratedColumn<String>(
      'remote_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarCachePathMeta =
      const VerificationMeta('avatarCachePath');
  @override
  late final GeneratedColumn<String> avatarCachePath = GeneratedColumn<String>(
      'avatar_cache_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backgroundUrlMeta =
      const VerificationMeta('backgroundUrl');
  @override
  late final GeneratedColumn<String> backgroundUrl = GeneratedColumn<String>(
      'background_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backgroundCachePathMeta =
      const VerificationMeta('backgroundCachePath');
  @override
  late final GeneratedColumn<String> backgroundCachePath =
      GeneratedColumn<String>('background_cache_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _userConfirmedMeta =
      const VerificationMeta('userConfirmed');
  @override
  late final GeneratedColumn<bool> userConfirmed = GeneratedColumn<bool>(
      'user_confirmed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("user_confirmed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _retryAfterMeta =
      const VerificationMeta('retryAfter');
  @override
  late final GeneratedColumn<DateTime> retryAfter = GeneratedColumn<DateTime>(
      'retry_after', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        artistKey,
        displayName,
        sourceProviderId,
        remoteArtistId,
        remoteName,
        avatarUrl,
        avatarCachePath,
        backgroundUrl,
        backgroundCachePath,
        description,
        confidence,
        userConfirmed,
        status,
        fetchedAt,
        retryAfter
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_artist_metadata';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalArtistMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artist_key')) {
      context.handle(_artistKeyMeta,
          artistKey.isAcceptableOrUnknown(data['artist_key']!, _artistKeyMeta));
    } else if (isInserting) {
      context.missing(_artistKeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('source_provider_id')) {
      context.handle(
          _sourceProviderIdMeta,
          sourceProviderId.isAcceptableOrUnknown(
              data['source_provider_id']!, _sourceProviderIdMeta));
    }
    if (data.containsKey('remote_artist_id')) {
      context.handle(
          _remoteArtistIdMeta,
          remoteArtistId.isAcceptableOrUnknown(
              data['remote_artist_id']!, _remoteArtistIdMeta));
    }
    if (data.containsKey('remote_name')) {
      context.handle(
          _remoteNameMeta,
          remoteName.isAcceptableOrUnknown(
              data['remote_name']!, _remoteNameMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('avatar_cache_path')) {
      context.handle(
          _avatarCachePathMeta,
          avatarCachePath.isAcceptableOrUnknown(
              data['avatar_cache_path']!, _avatarCachePathMeta));
    }
    if (data.containsKey('background_url')) {
      context.handle(
          _backgroundUrlMeta,
          backgroundUrl.isAcceptableOrUnknown(
              data['background_url']!, _backgroundUrlMeta));
    }
    if (data.containsKey('background_cache_path')) {
      context.handle(
          _backgroundCachePathMeta,
          backgroundCachePath.isAcceptableOrUnknown(
              data['background_cache_path']!, _backgroundCachePathMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('user_confirmed')) {
      context.handle(
          _userConfirmedMeta,
          userConfirmed.isAcceptableOrUnknown(
              data['user_confirmed']!, _userConfirmedMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    }
    if (data.containsKey('retry_after')) {
      context.handle(
          _retryAfterMeta,
          retryAfter.isAcceptableOrUnknown(
              data['retry_after']!, _retryAfterMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {artistKey};
  @override
  StoredLocalArtistMetadataData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalArtistMetadataData(
      artistKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_key'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      sourceProviderId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_provider_id']),
      remoteArtistId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_artist_id']),
      remoteName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_name']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      avatarCachePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}avatar_cache_path']),
      backgroundUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}background_url']),
      backgroundCachePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}background_cache_path']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence']),
      userConfirmed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}user_confirmed'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at']),
      retryAfter: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}retry_after']),
    );
  }

  @override
  $StoredLocalArtistMetadataTable createAlias(String alias) {
    return $StoredLocalArtistMetadataTable(attachedDatabase, alias);
  }
}

class StoredLocalArtistMetadataData extends DataClass
    implements Insertable<StoredLocalArtistMetadataData> {
  final String artistKey;
  final String displayName;
  final String? sourceProviderId;
  final String? remoteArtistId;
  final String? remoteName;
  final String? avatarUrl;
  final String? avatarCachePath;
  final String? backgroundUrl;
  final String? backgroundCachePath;
  final String? description;
  final double? confidence;
  final bool userConfirmed;
  final String status;
  final DateTime? fetchedAt;
  final DateTime? retryAfter;
  const StoredLocalArtistMetadataData(
      {required this.artistKey,
      required this.displayName,
      this.sourceProviderId,
      this.remoteArtistId,
      this.remoteName,
      this.avatarUrl,
      this.avatarCachePath,
      this.backgroundUrl,
      this.backgroundCachePath,
      this.description,
      this.confidence,
      required this.userConfirmed,
      required this.status,
      this.fetchedAt,
      this.retryAfter});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artist_key'] = Variable<String>(artistKey);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || sourceProviderId != null) {
      map['source_provider_id'] = Variable<String>(sourceProviderId);
    }
    if (!nullToAbsent || remoteArtistId != null) {
      map['remote_artist_id'] = Variable<String>(remoteArtistId);
    }
    if (!nullToAbsent || remoteName != null) {
      map['remote_name'] = Variable<String>(remoteName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || avatarCachePath != null) {
      map['avatar_cache_path'] = Variable<String>(avatarCachePath);
    }
    if (!nullToAbsent || backgroundUrl != null) {
      map['background_url'] = Variable<String>(backgroundUrl);
    }
    if (!nullToAbsent || backgroundCachePath != null) {
      map['background_cache_path'] = Variable<String>(backgroundCachePath);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['user_confirmed'] = Variable<bool>(userConfirmed);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    if (!nullToAbsent || retryAfter != null) {
      map['retry_after'] = Variable<DateTime>(retryAfter);
    }
    return map;
  }

  StoredLocalArtistMetadataCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalArtistMetadataCompanion(
      artistKey: Value(artistKey),
      displayName: Value(displayName),
      sourceProviderId: sourceProviderId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceProviderId),
      remoteArtistId: remoteArtistId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteArtistId),
      remoteName: remoteName == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      avatarCachePath: avatarCachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarCachePath),
      backgroundUrl: backgroundUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundUrl),
      backgroundCachePath: backgroundCachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundCachePath),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      userConfirmed: Value(userConfirmed),
      status: Value(status),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      retryAfter: retryAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(retryAfter),
    );
  }

  factory StoredLocalArtistMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalArtistMetadataData(
      artistKey: serializer.fromJson<String>(json['artistKey']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sourceProviderId: serializer.fromJson<String?>(json['sourceProviderId']),
      remoteArtistId: serializer.fromJson<String?>(json['remoteArtistId']),
      remoteName: serializer.fromJson<String?>(json['remoteName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      avatarCachePath: serializer.fromJson<String?>(json['avatarCachePath']),
      backgroundUrl: serializer.fromJson<String?>(json['backgroundUrl']),
      backgroundCachePath:
          serializer.fromJson<String?>(json['backgroundCachePath']),
      description: serializer.fromJson<String?>(json['description']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      userConfirmed: serializer.fromJson<bool>(json['userConfirmed']),
      status: serializer.fromJson<String>(json['status']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      retryAfter: serializer.fromJson<DateTime?>(json['retryAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artistKey': serializer.toJson<String>(artistKey),
      'displayName': serializer.toJson<String>(displayName),
      'sourceProviderId': serializer.toJson<String?>(sourceProviderId),
      'remoteArtistId': serializer.toJson<String?>(remoteArtistId),
      'remoteName': serializer.toJson<String?>(remoteName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'avatarCachePath': serializer.toJson<String?>(avatarCachePath),
      'backgroundUrl': serializer.toJson<String?>(backgroundUrl),
      'backgroundCachePath': serializer.toJson<String?>(backgroundCachePath),
      'description': serializer.toJson<String?>(description),
      'confidence': serializer.toJson<double?>(confidence),
      'userConfirmed': serializer.toJson<bool>(userConfirmed),
      'status': serializer.toJson<String>(status),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'retryAfter': serializer.toJson<DateTime?>(retryAfter),
    };
  }

  StoredLocalArtistMetadataData copyWith(
          {String? artistKey,
          String? displayName,
          Value<String?> sourceProviderId = const Value.absent(),
          Value<String?> remoteArtistId = const Value.absent(),
          Value<String?> remoteName = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> avatarCachePath = const Value.absent(),
          Value<String?> backgroundUrl = const Value.absent(),
          Value<String?> backgroundCachePath = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<double?> confidence = const Value.absent(),
          bool? userConfirmed,
          String? status,
          Value<DateTime?> fetchedAt = const Value.absent(),
          Value<DateTime?> retryAfter = const Value.absent()}) =>
      StoredLocalArtistMetadataData(
        artistKey: artistKey ?? this.artistKey,
        displayName: displayName ?? this.displayName,
        sourceProviderId: sourceProviderId.present
            ? sourceProviderId.value
            : this.sourceProviderId,
        remoteArtistId:
            remoteArtistId.present ? remoteArtistId.value : this.remoteArtistId,
        remoteName: remoteName.present ? remoteName.value : this.remoteName,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        avatarCachePath: avatarCachePath.present
            ? avatarCachePath.value
            : this.avatarCachePath,
        backgroundUrl:
            backgroundUrl.present ? backgroundUrl.value : this.backgroundUrl,
        backgroundCachePath: backgroundCachePath.present
            ? backgroundCachePath.value
            : this.backgroundCachePath,
        description: description.present ? description.value : this.description,
        confidence: confidence.present ? confidence.value : this.confidence,
        userConfirmed: userConfirmed ?? this.userConfirmed,
        status: status ?? this.status,
        fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
        retryAfter: retryAfter.present ? retryAfter.value : this.retryAfter,
      );
  StoredLocalArtistMetadataData copyWithCompanion(
      StoredLocalArtistMetadataCompanion data) {
    return StoredLocalArtistMetadataData(
      artistKey: data.artistKey.present ? data.artistKey.value : this.artistKey,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      sourceProviderId: data.sourceProviderId.present
          ? data.sourceProviderId.value
          : this.sourceProviderId,
      remoteArtistId: data.remoteArtistId.present
          ? data.remoteArtistId.value
          : this.remoteArtistId,
      remoteName:
          data.remoteName.present ? data.remoteName.value : this.remoteName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      avatarCachePath: data.avatarCachePath.present
          ? data.avatarCachePath.value
          : this.avatarCachePath,
      backgroundUrl: data.backgroundUrl.present
          ? data.backgroundUrl.value
          : this.backgroundUrl,
      backgroundCachePath: data.backgroundCachePath.present
          ? data.backgroundCachePath.value
          : this.backgroundCachePath,
      description:
          data.description.present ? data.description.value : this.description,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      userConfirmed: data.userConfirmed.present
          ? data.userConfirmed.value
          : this.userConfirmed,
      status: data.status.present ? data.status.value : this.status,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      retryAfter:
          data.retryAfter.present ? data.retryAfter.value : this.retryAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalArtistMetadataData(')
          ..write('artistKey: $artistKey, ')
          ..write('displayName: $displayName, ')
          ..write('sourceProviderId: $sourceProviderId, ')
          ..write('remoteArtistId: $remoteArtistId, ')
          ..write('remoteName: $remoteName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('avatarCachePath: $avatarCachePath, ')
          ..write('backgroundUrl: $backgroundUrl, ')
          ..write('backgroundCachePath: $backgroundCachePath, ')
          ..write('description: $description, ')
          ..write('confidence: $confidence, ')
          ..write('userConfirmed: $userConfirmed, ')
          ..write('status: $status, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('retryAfter: $retryAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      artistKey,
      displayName,
      sourceProviderId,
      remoteArtistId,
      remoteName,
      avatarUrl,
      avatarCachePath,
      backgroundUrl,
      backgroundCachePath,
      description,
      confidence,
      userConfirmed,
      status,
      fetchedAt,
      retryAfter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalArtistMetadataData &&
          other.artistKey == this.artistKey &&
          other.displayName == this.displayName &&
          other.sourceProviderId == this.sourceProviderId &&
          other.remoteArtistId == this.remoteArtistId &&
          other.remoteName == this.remoteName &&
          other.avatarUrl == this.avatarUrl &&
          other.avatarCachePath == this.avatarCachePath &&
          other.backgroundUrl == this.backgroundUrl &&
          other.backgroundCachePath == this.backgroundCachePath &&
          other.description == this.description &&
          other.confidence == this.confidence &&
          other.userConfirmed == this.userConfirmed &&
          other.status == this.status &&
          other.fetchedAt == this.fetchedAt &&
          other.retryAfter == this.retryAfter);
}

class StoredLocalArtistMetadataCompanion
    extends UpdateCompanion<StoredLocalArtistMetadataData> {
  final Value<String> artistKey;
  final Value<String> displayName;
  final Value<String?> sourceProviderId;
  final Value<String?> remoteArtistId;
  final Value<String?> remoteName;
  final Value<String?> avatarUrl;
  final Value<String?> avatarCachePath;
  final Value<String?> backgroundUrl;
  final Value<String?> backgroundCachePath;
  final Value<String?> description;
  final Value<double?> confidence;
  final Value<bool> userConfirmed;
  final Value<String> status;
  final Value<DateTime?> fetchedAt;
  final Value<DateTime?> retryAfter;
  final Value<int> rowid;
  const StoredLocalArtistMetadataCompanion({
    this.artistKey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sourceProviderId = const Value.absent(),
    this.remoteArtistId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.avatarCachePath = const Value.absent(),
    this.backgroundUrl = const Value.absent(),
    this.backgroundCachePath = const Value.absent(),
    this.description = const Value.absent(),
    this.confidence = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    this.status = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.retryAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalArtistMetadataCompanion.insert({
    required String artistKey,
    required String displayName,
    this.sourceProviderId = const Value.absent(),
    this.remoteArtistId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.avatarCachePath = const Value.absent(),
    this.backgroundUrl = const Value.absent(),
    this.backgroundCachePath = const Value.absent(),
    this.description = const Value.absent(),
    this.confidence = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    required String status,
    this.fetchedAt = const Value.absent(),
    this.retryAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : artistKey = Value(artistKey),
        displayName = Value(displayName),
        status = Value(status);
  static Insertable<StoredLocalArtistMetadataData> custom({
    Expression<String>? artistKey,
    Expression<String>? displayName,
    Expression<String>? sourceProviderId,
    Expression<String>? remoteArtistId,
    Expression<String>? remoteName,
    Expression<String>? avatarUrl,
    Expression<String>? avatarCachePath,
    Expression<String>? backgroundUrl,
    Expression<String>? backgroundCachePath,
    Expression<String>? description,
    Expression<double>? confidence,
    Expression<bool>? userConfirmed,
    Expression<String>? status,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? retryAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artistKey != null) 'artist_key': artistKey,
      if (displayName != null) 'display_name': displayName,
      if (sourceProviderId != null) 'source_provider_id': sourceProviderId,
      if (remoteArtistId != null) 'remote_artist_id': remoteArtistId,
      if (remoteName != null) 'remote_name': remoteName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (avatarCachePath != null) 'avatar_cache_path': avatarCachePath,
      if (backgroundUrl != null) 'background_url': backgroundUrl,
      if (backgroundCachePath != null)
        'background_cache_path': backgroundCachePath,
      if (description != null) 'description': description,
      if (confidence != null) 'confidence': confidence,
      if (userConfirmed != null) 'user_confirmed': userConfirmed,
      if (status != null) 'status': status,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (retryAfter != null) 'retry_after': retryAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalArtistMetadataCompanion copyWith(
      {Value<String>? artistKey,
      Value<String>? displayName,
      Value<String?>? sourceProviderId,
      Value<String?>? remoteArtistId,
      Value<String?>? remoteName,
      Value<String?>? avatarUrl,
      Value<String?>? avatarCachePath,
      Value<String?>? backgroundUrl,
      Value<String?>? backgroundCachePath,
      Value<String?>? description,
      Value<double?>? confidence,
      Value<bool>? userConfirmed,
      Value<String>? status,
      Value<DateTime?>? fetchedAt,
      Value<DateTime?>? retryAfter,
      Value<int>? rowid}) {
    return StoredLocalArtistMetadataCompanion(
      artistKey: artistKey ?? this.artistKey,
      displayName: displayName ?? this.displayName,
      sourceProviderId: sourceProviderId ?? this.sourceProviderId,
      remoteArtistId: remoteArtistId ?? this.remoteArtistId,
      remoteName: remoteName ?? this.remoteName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarCachePath: avatarCachePath ?? this.avatarCachePath,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      backgroundCachePath: backgroundCachePath ?? this.backgroundCachePath,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      status: status ?? this.status,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      retryAfter: retryAfter ?? this.retryAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artistKey.present) {
      map['artist_key'] = Variable<String>(artistKey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sourceProviderId.present) {
      map['source_provider_id'] = Variable<String>(sourceProviderId.value);
    }
    if (remoteArtistId.present) {
      map['remote_artist_id'] = Variable<String>(remoteArtistId.value);
    }
    if (remoteName.present) {
      map['remote_name'] = Variable<String>(remoteName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (avatarCachePath.present) {
      map['avatar_cache_path'] = Variable<String>(avatarCachePath.value);
    }
    if (backgroundUrl.present) {
      map['background_url'] = Variable<String>(backgroundUrl.value);
    }
    if (backgroundCachePath.present) {
      map['background_cache_path'] =
          Variable<String>(backgroundCachePath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (userConfirmed.present) {
      map['user_confirmed'] = Variable<bool>(userConfirmed.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (retryAfter.present) {
      map['retry_after'] = Variable<DateTime>(retryAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalArtistMetadataCompanion(')
          ..write('artistKey: $artistKey, ')
          ..write('displayName: $displayName, ')
          ..write('sourceProviderId: $sourceProviderId, ')
          ..write('remoteArtistId: $remoteArtistId, ')
          ..write('remoteName: $remoteName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('avatarCachePath: $avatarCachePath, ')
          ..write('backgroundUrl: $backgroundUrl, ')
          ..write('backgroundCachePath: $backgroundCachePath, ')
          ..write('description: $description, ')
          ..write('confidence: $confidence, ')
          ..write('userConfirmed: $userConfirmed, ')
          ..write('status: $status, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('retryAfter: $retryAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredLocalTrackMatchesTable extends StoredLocalTrackMatches
    with TableInfo<$StoredLocalTrackMatchesTable, StoredLocalTrackMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredLocalTrackMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerTrackIdMeta =
      const VerificationMeta('providerTrackId');
  @override
  late final GeneratedColumn<String> providerTrackId = GeneratedColumn<String>(
      'provider_track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localTrackIdMeta =
      const VerificationMeta('localTrackId');
  @override
  late final GeneratedColumn<String> localTrackId = GeneratedColumn<String>(
      'local_track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchMethodMeta =
      const VerificationMeta('matchMethod');
  @override
  late final GeneratedColumn<String> matchMethod = GeneratedColumn<String>(
      'match_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        providerId,
        providerTrackId,
        localTrackId,
        matchMethod,
        confidence,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_local_track_matches';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoredLocalTrackMatche> instance,
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
    if (data.containsKey('provider_track_id')) {
      context.handle(
          _providerTrackIdMeta,
          providerTrackId.isAcceptableOrUnknown(
              data['provider_track_id']!, _providerTrackIdMeta));
    } else if (isInserting) {
      context.missing(_providerTrackIdMeta);
    }
    if (data.containsKey('local_track_id')) {
      context.handle(
          _localTrackIdMeta,
          localTrackId.isAcceptableOrUnknown(
              data['local_track_id']!, _localTrackIdMeta));
    } else if (isInserting) {
      context.missing(_localTrackIdMeta);
    }
    if (data.containsKey('match_method')) {
      context.handle(
          _matchMethodMeta,
          matchMethod.isAcceptableOrUnknown(
              data['match_method']!, _matchMethodMeta));
    } else if (isInserting) {
      context.missing(_matchMethodMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, providerTrackId};
  @override
  StoredLocalTrackMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLocalTrackMatche(
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      providerTrackId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_track_id'])!,
      localTrackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_track_id'])!,
      matchMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_method'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StoredLocalTrackMatchesTable createAlias(String alias) {
    return $StoredLocalTrackMatchesTable(attachedDatabase, alias);
  }
}

class StoredLocalTrackMatche extends DataClass
    implements Insertable<StoredLocalTrackMatche> {
  final String providerId;
  final String providerTrackId;
  final String localTrackId;
  final String matchMethod;
  final double confidence;
  final DateTime updatedAt;
  const StoredLocalTrackMatche(
      {required this.providerId,
      required this.providerTrackId,
      required this.localTrackId,
      required this.matchMethod,
      required this.confidence,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['provider_track_id'] = Variable<String>(providerTrackId);
    map['local_track_id'] = Variable<String>(localTrackId);
    map['match_method'] = Variable<String>(matchMethod);
    map['confidence'] = Variable<double>(confidence);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoredLocalTrackMatchesCompanion toCompanion(bool nullToAbsent) {
    return StoredLocalTrackMatchesCompanion(
      providerId: Value(providerId),
      providerTrackId: Value(providerTrackId),
      localTrackId: Value(localTrackId),
      matchMethod: Value(matchMethod),
      confidence: Value(confidence),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoredLocalTrackMatche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLocalTrackMatche(
      providerId: serializer.fromJson<String>(json['providerId']),
      providerTrackId: serializer.fromJson<String>(json['providerTrackId']),
      localTrackId: serializer.fromJson<String>(json['localTrackId']),
      matchMethod: serializer.fromJson<String>(json['matchMethod']),
      confidence: serializer.fromJson<double>(json['confidence']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'providerTrackId': serializer.toJson<String>(providerTrackId),
      'localTrackId': serializer.toJson<String>(localTrackId),
      'matchMethod': serializer.toJson<String>(matchMethod),
      'confidence': serializer.toJson<double>(confidence),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoredLocalTrackMatche copyWith(
          {String? providerId,
          String? providerTrackId,
          String? localTrackId,
          String? matchMethod,
          double? confidence,
          DateTime? updatedAt}) =>
      StoredLocalTrackMatche(
        providerId: providerId ?? this.providerId,
        providerTrackId: providerTrackId ?? this.providerTrackId,
        localTrackId: localTrackId ?? this.localTrackId,
        matchMethod: matchMethod ?? this.matchMethod,
        confidence: confidence ?? this.confidence,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StoredLocalTrackMatche copyWithCompanion(
      StoredLocalTrackMatchesCompanion data) {
    return StoredLocalTrackMatche(
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      providerTrackId: data.providerTrackId.present
          ? data.providerTrackId.value
          : this.providerTrackId,
      localTrackId: data.localTrackId.present
          ? data.localTrackId.value
          : this.localTrackId,
      matchMethod:
          data.matchMethod.present ? data.matchMethod.value : this.matchMethod,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLocalTrackMatche(')
          ..write('providerId: $providerId, ')
          ..write('providerTrackId: $providerTrackId, ')
          ..write('localTrackId: $localTrackId, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('confidence: $confidence, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(providerId, providerTrackId, localTrackId,
      matchMethod, confidence, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLocalTrackMatche &&
          other.providerId == this.providerId &&
          other.providerTrackId == this.providerTrackId &&
          other.localTrackId == this.localTrackId &&
          other.matchMethod == this.matchMethod &&
          other.confidence == this.confidence &&
          other.updatedAt == this.updatedAt);
}

class StoredLocalTrackMatchesCompanion
    extends UpdateCompanion<StoredLocalTrackMatche> {
  final Value<String> providerId;
  final Value<String> providerTrackId;
  final Value<String> localTrackId;
  final Value<String> matchMethod;
  final Value<double> confidence;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoredLocalTrackMatchesCompanion({
    this.providerId = const Value.absent(),
    this.providerTrackId = const Value.absent(),
    this.localTrackId = const Value.absent(),
    this.matchMethod = const Value.absent(),
    this.confidence = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredLocalTrackMatchesCompanion.insert({
    required String providerId,
    required String providerTrackId,
    required String localTrackId,
    required String matchMethod,
    required double confidence,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : providerId = Value(providerId),
        providerTrackId = Value(providerTrackId),
        localTrackId = Value(localTrackId),
        matchMethod = Value(matchMethod),
        confidence = Value(confidence),
        updatedAt = Value(updatedAt);
  static Insertable<StoredLocalTrackMatche> custom({
    Expression<String>? providerId,
    Expression<String>? providerTrackId,
    Expression<String>? localTrackId,
    Expression<String>? matchMethod,
    Expression<double>? confidence,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (providerTrackId != null) 'provider_track_id': providerTrackId,
      if (localTrackId != null) 'local_track_id': localTrackId,
      if (matchMethod != null) 'match_method': matchMethod,
      if (confidence != null) 'confidence': confidence,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredLocalTrackMatchesCompanion copyWith(
      {Value<String>? providerId,
      Value<String>? providerTrackId,
      Value<String>? localTrackId,
      Value<String>? matchMethod,
      Value<double>? confidence,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StoredLocalTrackMatchesCompanion(
      providerId: providerId ?? this.providerId,
      providerTrackId: providerTrackId ?? this.providerTrackId,
      localTrackId: localTrackId ?? this.localTrackId,
      matchMethod: matchMethod ?? this.matchMethod,
      confidence: confidence ?? this.confidence,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (providerTrackId.present) {
      map['provider_track_id'] = Variable<String>(providerTrackId.value);
    }
    if (localTrackId.present) {
      map['local_track_id'] = Variable<String>(localTrackId.value);
    }
    if (matchMethod.present) {
      map['match_method'] = Variable<String>(matchMethod.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
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
    return (StringBuffer('StoredLocalTrackMatchesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('providerTrackId: $providerTrackId, ')
          ..write('localTrackId: $localTrackId, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('confidence: $confidence, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $StoredLocalLibraryRootsTable storedLocalLibraryRoots =
      $StoredLocalLibraryRootsTable(this);
  late final $StoredLocalLibraryTracksTable storedLocalLibraryTracks =
      $StoredLocalLibraryTracksTable(this);
  late final $StoredLocalLibraryFavoritesTable storedLocalLibraryFavorites =
      $StoredLocalLibraryFavoritesTable(this);
  late final $StoredLocalArtistMetadataTable storedLocalArtistMetadata =
      $StoredLocalArtistMetadataTable(this);
  late final $StoredLocalTrackMatchesTable storedLocalTrackMatches =
      $StoredLocalTrackMatchesTable(this);
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
        audioCacheSettings,
        storedLocalLibraryRoots,
        storedLocalLibraryTracks,
        storedLocalLibraryFavorites,
        storedLocalArtistMetadata,
        storedLocalTrackMatches
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
typedef $$StoredLocalLibraryRootsTableCreateCompanionBuilder
    = StoredLocalLibraryRootsCompanion Function({
  required String id,
  required String path,
  required String displayName,
  required String scanState,
  Value<DateTime?> lastScannedAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$StoredLocalLibraryRootsTableUpdateCompanionBuilder
    = StoredLocalLibraryRootsCompanion Function({
  Value<String> id,
  Value<String> path,
  Value<String> displayName,
  Value<String> scanState,
  Value<DateTime?> lastScannedAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$StoredLocalLibraryRootsTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryRootsTable> {
  $$StoredLocalLibraryRootsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scanState => $composableBuilder(
      column: $table.scanState, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastScannedAt => $composableBuilder(
      column: $table.lastScannedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalLibraryRootsTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryRootsTable> {
  $$StoredLocalLibraryRootsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scanState => $composableBuilder(
      column: $table.scanState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastScannedAt => $composableBuilder(
      column: $table.lastScannedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalLibraryRootsTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryRootsTable> {
  $$StoredLocalLibraryRootsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get scanState =>
      $composableBuilder(column: $table.scanState, builder: (column) => column);

  GeneratedColumn<DateTime> get lastScannedAt => $composableBuilder(
      column: $table.lastScannedAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$StoredLocalLibraryRootsTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalLibraryRootsTable,
    StoredLocalLibraryRoot,
    $$StoredLocalLibraryRootsTableFilterComposer,
    $$StoredLocalLibraryRootsTableOrderingComposer,
    $$StoredLocalLibraryRootsTableAnnotationComposer,
    $$StoredLocalLibraryRootsTableCreateCompanionBuilder,
    $$StoredLocalLibraryRootsTableUpdateCompanionBuilder,
    (
      StoredLocalLibraryRoot,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryRootsTable,
          StoredLocalLibraryRoot>
    ),
    StoredLocalLibraryRoot,
    PrefetchHooks Function()> {
  $$StoredLocalLibraryRootsTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalLibraryRootsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalLibraryRootsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalLibraryRootsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalLibraryRootsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> scanState = const Value.absent(),
            Value<DateTime?> lastScannedAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryRootsCompanion(
            id: id,
            path: path,
            displayName: displayName,
            scanState: scanState,
            lastScannedAt: lastScannedAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String path,
            required String displayName,
            required String scanState,
            Value<DateTime?> lastScannedAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryRootsCompanion.insert(
            id: id,
            path: path,
            displayName: displayName,
            scanState: scanState,
            lastScannedAt: lastScannedAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalLibraryRootsTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalLibraryRootsTable,
        StoredLocalLibraryRoot,
        $$StoredLocalLibraryRootsTableFilterComposer,
        $$StoredLocalLibraryRootsTableOrderingComposer,
        $$StoredLocalLibraryRootsTableAnnotationComposer,
        $$StoredLocalLibraryRootsTableCreateCompanionBuilder,
        $$StoredLocalLibraryRootsTableUpdateCompanionBuilder,
        (
          StoredLocalLibraryRoot,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryRootsTable,
              StoredLocalLibraryRoot>
        ),
        StoredLocalLibraryRoot,
        PrefetchHooks Function()>;
typedef $$StoredLocalLibraryTracksTableCreateCompanionBuilder
    = StoredLocalLibraryTracksCompanion Function({
  required String id,
  required String rootId,
  required String filePath,
  required String relativePath,
  required int fileSize,
  required DateTime modifiedAt,
  required String fingerprint,
  required String title,
  required String artistsJson,
  required int durationMs,
  required String format,
  Value<String?> album,
  Value<String?> genre,
  Value<String> genresJson,
  Value<String?> embeddedAlbumArtist,
  Value<String?> albumArtist,
  Value<String> albumArtistSource,
  Value<String?> albumEditionKey,
  Value<String?> isrc,
  Value<DateTime?> addedAt,
  Value<int?> bitRate,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<String> normalizedTitle,
  Value<String> normalizedArtists,
  Value<String> normalizedAlbum,
  Value<int?> year,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<String?> lyrics,
  Value<String?> artworkPath,
  Value<bool> isAvailable,
  Value<int> rowid,
});
typedef $$StoredLocalLibraryTracksTableUpdateCompanionBuilder
    = StoredLocalLibraryTracksCompanion Function({
  Value<String> id,
  Value<String> rootId,
  Value<String> filePath,
  Value<String> relativePath,
  Value<int> fileSize,
  Value<DateTime> modifiedAt,
  Value<String> fingerprint,
  Value<String> title,
  Value<String> artistsJson,
  Value<int> durationMs,
  Value<String> format,
  Value<String?> album,
  Value<String?> genre,
  Value<String> genresJson,
  Value<String?> embeddedAlbumArtist,
  Value<String?> albumArtist,
  Value<String> albumArtistSource,
  Value<String?> albumEditionKey,
  Value<String?> isrc,
  Value<DateTime?> addedAt,
  Value<int?> bitRate,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<String> normalizedTitle,
  Value<String> normalizedArtists,
  Value<String> normalizedAlbum,
  Value<int?> year,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<String?> lyrics,
  Value<String?> artworkPath,
  Value<bool> isAvailable,
  Value<int> rowid,
});

class $$StoredLocalLibraryTracksTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryTracksTable> {
  $$StoredLocalLibraryTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootId => $composableBuilder(
      column: $table.rootId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistsJson => $composableBuilder(
      column: $table.artistsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genresJson => $composableBuilder(
      column: $table.genresJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get embeddedAlbumArtist => $composableBuilder(
      column: $table.embeddedAlbumArtist,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArtist => $composableBuilder(
      column: $table.albumArtist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArtistSource => $composableBuilder(
      column: $table.albumArtistSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumEditionKey => $composableBuilder(
      column: $table.albumEditionKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get isrc => $composableBuilder(
      column: $table.isrc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bitRate => $composableBuilder(
      column: $table.bitRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bitDepth => $composableBuilder(
      column: $table.bitDepth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
      column: $table.normalizedTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedArtists => $composableBuilder(
      column: $table.normalizedArtists,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedAlbum => $composableBuilder(
      column: $table.normalizedAlbum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artworkPath => $composableBuilder(
      column: $table.artworkPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalLibraryTracksTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryTracksTable> {
  $$StoredLocalLibraryTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootId => $composableBuilder(
      column: $table.rootId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistsJson => $composableBuilder(
      column: $table.artistsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genresJson => $composableBuilder(
      column: $table.genresJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get embeddedAlbumArtist => $composableBuilder(
      column: $table.embeddedAlbumArtist,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArtist => $composableBuilder(
      column: $table.albumArtist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArtistSource => $composableBuilder(
      column: $table.albumArtistSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumEditionKey => $composableBuilder(
      column: $table.albumEditionKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get isrc => $composableBuilder(
      column: $table.isrc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bitRate => $composableBuilder(
      column: $table.bitRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bitDepth => $composableBuilder(
      column: $table.bitDepth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
      column: $table.normalizedTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedArtists => $composableBuilder(
      column: $table.normalizedArtists,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedAlbum => $composableBuilder(
      column: $table.normalizedAlbum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artworkPath => $composableBuilder(
      column: $table.artworkPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalLibraryTracksTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryTracksTable> {
  $$StoredLocalLibraryTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rootId =>
      $composableBuilder(column: $table.rootId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistsJson => $composableBuilder(
      column: $table.artistsJson, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get genresJson => $composableBuilder(
      column: $table.genresJson, builder: (column) => column);

  GeneratedColumn<String> get embeddedAlbumArtist => $composableBuilder(
      column: $table.embeddedAlbumArtist, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
      column: $table.albumArtist, builder: (column) => column);

  GeneratedColumn<String> get albumArtistSource => $composableBuilder(
      column: $table.albumArtistSource, builder: (column) => column);

  GeneratedColumn<String> get albumEditionKey => $composableBuilder(
      column: $table.albumEditionKey, builder: (column) => column);

  GeneratedColumn<String> get isrc =>
      $composableBuilder(column: $table.isrc, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get bitRate =>
      $composableBuilder(column: $table.bitRate, builder: (column) => column);

  GeneratedColumn<int> get sampleRate => $composableBuilder(
      column: $table.sampleRate, builder: (column) => column);

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
      column: $table.normalizedTitle, builder: (column) => column);

  GeneratedColumn<String> get normalizedArtists => $composableBuilder(
      column: $table.normalizedArtists, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlbum => $composableBuilder(
      column: $table.normalizedAlbum, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => column);

  GeneratedColumn<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => column);

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumn<String> get artworkPath => $composableBuilder(
      column: $table.artworkPath, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => column);
}

class $$StoredLocalLibraryTracksTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalLibraryTracksTable,
    StoredLocalLibraryTrack,
    $$StoredLocalLibraryTracksTableFilterComposer,
    $$StoredLocalLibraryTracksTableOrderingComposer,
    $$StoredLocalLibraryTracksTableAnnotationComposer,
    $$StoredLocalLibraryTracksTableCreateCompanionBuilder,
    $$StoredLocalLibraryTracksTableUpdateCompanionBuilder,
    (
      StoredLocalLibraryTrack,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryTracksTable,
          StoredLocalLibraryTrack>
    ),
    StoredLocalLibraryTrack,
    PrefetchHooks Function()> {
  $$StoredLocalLibraryTracksTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalLibraryTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalLibraryTracksTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalLibraryTracksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalLibraryTracksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rootId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<String> fingerprint = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> artistsJson = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String> genresJson = const Value.absent(),
            Value<String?> embeddedAlbumArtist = const Value.absent(),
            Value<String?> albumArtist = const Value.absent(),
            Value<String> albumArtistSource = const Value.absent(),
            Value<String?> albumEditionKey = const Value.absent(),
            Value<String?> isrc = const Value.absent(),
            Value<DateTime?> addedAt = const Value.absent(),
            Value<int?> bitRate = const Value.absent(),
            Value<int?> sampleRate = const Value.absent(),
            Value<int?> bitDepth = const Value.absent(),
            Value<String> normalizedTitle = const Value.absent(),
            Value<String> normalizedArtists = const Value.absent(),
            Value<String> normalizedAlbum = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> discNumber = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> artworkPath = const Value.absent(),
            Value<bool> isAvailable = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryTracksCompanion(
            id: id,
            rootId: rootId,
            filePath: filePath,
            relativePath: relativePath,
            fileSize: fileSize,
            modifiedAt: modifiedAt,
            fingerprint: fingerprint,
            title: title,
            artistsJson: artistsJson,
            durationMs: durationMs,
            format: format,
            album: album,
            genre: genre,
            genresJson: genresJson,
            embeddedAlbumArtist: embeddedAlbumArtist,
            albumArtist: albumArtist,
            albumArtistSource: albumArtistSource,
            albumEditionKey: albumEditionKey,
            isrc: isrc,
            addedAt: addedAt,
            bitRate: bitRate,
            sampleRate: sampleRate,
            bitDepth: bitDepth,
            normalizedTitle: normalizedTitle,
            normalizedArtists: normalizedArtists,
            normalizedAlbum: normalizedAlbum,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            lyrics: lyrics,
            artworkPath: artworkPath,
            isAvailable: isAvailable,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rootId,
            required String filePath,
            required String relativePath,
            required int fileSize,
            required DateTime modifiedAt,
            required String fingerprint,
            required String title,
            required String artistsJson,
            required int durationMs,
            required String format,
            Value<String?> album = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String> genresJson = const Value.absent(),
            Value<String?> embeddedAlbumArtist = const Value.absent(),
            Value<String?> albumArtist = const Value.absent(),
            Value<String> albumArtistSource = const Value.absent(),
            Value<String?> albumEditionKey = const Value.absent(),
            Value<String?> isrc = const Value.absent(),
            Value<DateTime?> addedAt = const Value.absent(),
            Value<int?> bitRate = const Value.absent(),
            Value<int?> sampleRate = const Value.absent(),
            Value<int?> bitDepth = const Value.absent(),
            Value<String> normalizedTitle = const Value.absent(),
            Value<String> normalizedArtists = const Value.absent(),
            Value<String> normalizedAlbum = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> discNumber = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> artworkPath = const Value.absent(),
            Value<bool> isAvailable = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryTracksCompanion.insert(
            id: id,
            rootId: rootId,
            filePath: filePath,
            relativePath: relativePath,
            fileSize: fileSize,
            modifiedAt: modifiedAt,
            fingerprint: fingerprint,
            title: title,
            artistsJson: artistsJson,
            durationMs: durationMs,
            format: format,
            album: album,
            genre: genre,
            genresJson: genresJson,
            embeddedAlbumArtist: embeddedAlbumArtist,
            albumArtist: albumArtist,
            albumArtistSource: albumArtistSource,
            albumEditionKey: albumEditionKey,
            isrc: isrc,
            addedAt: addedAt,
            bitRate: bitRate,
            sampleRate: sampleRate,
            bitDepth: bitDepth,
            normalizedTitle: normalizedTitle,
            normalizedArtists: normalizedArtists,
            normalizedAlbum: normalizedAlbum,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            lyrics: lyrics,
            artworkPath: artworkPath,
            isAvailable: isAvailable,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalLibraryTracksTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalLibraryTracksTable,
        StoredLocalLibraryTrack,
        $$StoredLocalLibraryTracksTableFilterComposer,
        $$StoredLocalLibraryTracksTableOrderingComposer,
        $$StoredLocalLibraryTracksTableAnnotationComposer,
        $$StoredLocalLibraryTracksTableCreateCompanionBuilder,
        $$StoredLocalLibraryTracksTableUpdateCompanionBuilder,
        (
          StoredLocalLibraryTrack,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryTracksTable,
              StoredLocalLibraryTrack>
        ),
        StoredLocalLibraryTrack,
        PrefetchHooks Function()>;
typedef $$StoredLocalLibraryFavoritesTableCreateCompanionBuilder
    = StoredLocalLibraryFavoritesCompanion Function({
  required String trackId,
  required DateTime likedAt,
  Value<int> rowid,
});
typedef $$StoredLocalLibraryFavoritesTableUpdateCompanionBuilder
    = StoredLocalLibraryFavoritesCompanion Function({
  Value<String> trackId,
  Value<DateTime> likedAt,
  Value<int> rowid,
});

class $$StoredLocalLibraryFavoritesTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryFavoritesTable> {
  $$StoredLocalLibraryFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get likedAt => $composableBuilder(
      column: $table.likedAt, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalLibraryFavoritesTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryFavoritesTable> {
  $$StoredLocalLibraryFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get likedAt => $composableBuilder(
      column: $table.likedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalLibraryFavoritesTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalLibraryFavoritesTable> {
  $$StoredLocalLibraryFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => column);
}

class $$StoredLocalLibraryFavoritesTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalLibraryFavoritesTable,
    StoredLocalLibraryFavorite,
    $$StoredLocalLibraryFavoritesTableFilterComposer,
    $$StoredLocalLibraryFavoritesTableOrderingComposer,
    $$StoredLocalLibraryFavoritesTableAnnotationComposer,
    $$StoredLocalLibraryFavoritesTableCreateCompanionBuilder,
    $$StoredLocalLibraryFavoritesTableUpdateCompanionBuilder,
    (
      StoredLocalLibraryFavorite,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryFavoritesTable,
          StoredLocalLibraryFavorite>
    ),
    StoredLocalLibraryFavorite,
    PrefetchHooks Function()> {
  $$StoredLocalLibraryFavoritesTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalLibraryFavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalLibraryFavoritesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalLibraryFavoritesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalLibraryFavoritesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> trackId = const Value.absent(),
            Value<DateTime> likedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryFavoritesCompanion(
            trackId: trackId,
            likedAt: likedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String trackId,
            required DateTime likedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalLibraryFavoritesCompanion.insert(
            trackId: trackId,
            likedAt: likedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalLibraryFavoritesTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalLibraryFavoritesTable,
        StoredLocalLibraryFavorite,
        $$StoredLocalLibraryFavoritesTableFilterComposer,
        $$StoredLocalLibraryFavoritesTableOrderingComposer,
        $$StoredLocalLibraryFavoritesTableAnnotationComposer,
        $$StoredLocalLibraryFavoritesTableCreateCompanionBuilder,
        $$StoredLocalLibraryFavoritesTableUpdateCompanionBuilder,
        (
          StoredLocalLibraryFavorite,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalLibraryFavoritesTable,
              StoredLocalLibraryFavorite>
        ),
        StoredLocalLibraryFavorite,
        PrefetchHooks Function()>;
typedef $$StoredLocalArtistMetadataTableCreateCompanionBuilder
    = StoredLocalArtistMetadataCompanion Function({
  required String artistKey,
  required String displayName,
  Value<String?> sourceProviderId,
  Value<String?> remoteArtistId,
  Value<String?> remoteName,
  Value<String?> avatarUrl,
  Value<String?> avatarCachePath,
  Value<String?> backgroundUrl,
  Value<String?> backgroundCachePath,
  Value<String?> description,
  Value<double?> confidence,
  Value<bool> userConfirmed,
  required String status,
  Value<DateTime?> fetchedAt,
  Value<DateTime?> retryAfter,
  Value<int> rowid,
});
typedef $$StoredLocalArtistMetadataTableUpdateCompanionBuilder
    = StoredLocalArtistMetadataCompanion Function({
  Value<String> artistKey,
  Value<String> displayName,
  Value<String?> sourceProviderId,
  Value<String?> remoteArtistId,
  Value<String?> remoteName,
  Value<String?> avatarUrl,
  Value<String?> avatarCachePath,
  Value<String?> backgroundUrl,
  Value<String?> backgroundCachePath,
  Value<String?> description,
  Value<double?> confidence,
  Value<bool> userConfirmed,
  Value<String> status,
  Value<DateTime?> fetchedAt,
  Value<DateTime?> retryAfter,
  Value<int> rowid,
});

class $$StoredLocalArtistMetadataTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalArtistMetadataTable> {
  $$StoredLocalArtistMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get artistKey => $composableBuilder(
      column: $table.artistKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceProviderId => $composableBuilder(
      column: $table.sourceProviderId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteArtistId => $composableBuilder(
      column: $table.remoteArtistId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteName => $composableBuilder(
      column: $table.remoteName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarCachePath => $composableBuilder(
      column: $table.avatarCachePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundUrl => $composableBuilder(
      column: $table.backgroundUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundCachePath => $composableBuilder(
      column: $table.backgroundCachePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get userConfirmed => $composableBuilder(
      column: $table.userConfirmed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get retryAfter => $composableBuilder(
      column: $table.retryAfter, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalArtistMetadataTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalArtistMetadataTable> {
  $$StoredLocalArtistMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get artistKey => $composableBuilder(
      column: $table.artistKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceProviderId => $composableBuilder(
      column: $table.sourceProviderId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteArtistId => $composableBuilder(
      column: $table.remoteArtistId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteName => $composableBuilder(
      column: $table.remoteName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarCachePath => $composableBuilder(
      column: $table.avatarCachePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundUrl => $composableBuilder(
      column: $table.backgroundUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundCachePath => $composableBuilder(
      column: $table.backgroundCachePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get userConfirmed => $composableBuilder(
      column: $table.userConfirmed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get retryAfter => $composableBuilder(
      column: $table.retryAfter, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalArtistMetadataTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalArtistMetadataTable> {
  $$StoredLocalArtistMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get artistKey =>
      $composableBuilder(column: $table.artistKey, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get sourceProviderId => $composableBuilder(
      column: $table.sourceProviderId, builder: (column) => column);

  GeneratedColumn<String> get remoteArtistId => $composableBuilder(
      column: $table.remoteArtistId, builder: (column) => column);

  GeneratedColumn<String> get remoteName => $composableBuilder(
      column: $table.remoteName, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get avatarCachePath => $composableBuilder(
      column: $table.avatarCachePath, builder: (column) => column);

  GeneratedColumn<String> get backgroundUrl => $composableBuilder(
      column: $table.backgroundUrl, builder: (column) => column);

  GeneratedColumn<String> get backgroundCachePath => $composableBuilder(
      column: $table.backgroundCachePath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<bool> get userConfirmed => $composableBuilder(
      column: $table.userConfirmed, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get retryAfter => $composableBuilder(
      column: $table.retryAfter, builder: (column) => column);
}

class $$StoredLocalArtistMetadataTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalArtistMetadataTable,
    StoredLocalArtistMetadataData,
    $$StoredLocalArtistMetadataTableFilterComposer,
    $$StoredLocalArtistMetadataTableOrderingComposer,
    $$StoredLocalArtistMetadataTableAnnotationComposer,
    $$StoredLocalArtistMetadataTableCreateCompanionBuilder,
    $$StoredLocalArtistMetadataTableUpdateCompanionBuilder,
    (
      StoredLocalArtistMetadataData,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalArtistMetadataTable,
          StoredLocalArtistMetadataData>
    ),
    StoredLocalArtistMetadataData,
    PrefetchHooks Function()> {
  $$StoredLocalArtistMetadataTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalArtistMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalArtistMetadataTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalArtistMetadataTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalArtistMetadataTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> artistKey = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> sourceProviderId = const Value.absent(),
            Value<String?> remoteArtistId = const Value.absent(),
            Value<String?> remoteName = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> avatarCachePath = const Value.absent(),
            Value<String?> backgroundUrl = const Value.absent(),
            Value<String?> backgroundCachePath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<bool> userConfirmed = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> fetchedAt = const Value.absent(),
            Value<DateTime?> retryAfter = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalArtistMetadataCompanion(
            artistKey: artistKey,
            displayName: displayName,
            sourceProviderId: sourceProviderId,
            remoteArtistId: remoteArtistId,
            remoteName: remoteName,
            avatarUrl: avatarUrl,
            avatarCachePath: avatarCachePath,
            backgroundUrl: backgroundUrl,
            backgroundCachePath: backgroundCachePath,
            description: description,
            confidence: confidence,
            userConfirmed: userConfirmed,
            status: status,
            fetchedAt: fetchedAt,
            retryAfter: retryAfter,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String artistKey,
            required String displayName,
            Value<String?> sourceProviderId = const Value.absent(),
            Value<String?> remoteArtistId = const Value.absent(),
            Value<String?> remoteName = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> avatarCachePath = const Value.absent(),
            Value<String?> backgroundUrl = const Value.absent(),
            Value<String?> backgroundCachePath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<bool> userConfirmed = const Value.absent(),
            required String status,
            Value<DateTime?> fetchedAt = const Value.absent(),
            Value<DateTime?> retryAfter = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalArtistMetadataCompanion.insert(
            artistKey: artistKey,
            displayName: displayName,
            sourceProviderId: sourceProviderId,
            remoteArtistId: remoteArtistId,
            remoteName: remoteName,
            avatarUrl: avatarUrl,
            avatarCachePath: avatarCachePath,
            backgroundUrl: backgroundUrl,
            backgroundCachePath: backgroundCachePath,
            description: description,
            confidence: confidence,
            userConfirmed: userConfirmed,
            status: status,
            fetchedAt: fetchedAt,
            retryAfter: retryAfter,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalArtistMetadataTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalArtistMetadataTable,
        StoredLocalArtistMetadataData,
        $$StoredLocalArtistMetadataTableFilterComposer,
        $$StoredLocalArtistMetadataTableOrderingComposer,
        $$StoredLocalArtistMetadataTableAnnotationComposer,
        $$StoredLocalArtistMetadataTableCreateCompanionBuilder,
        $$StoredLocalArtistMetadataTableUpdateCompanionBuilder,
        (
          StoredLocalArtistMetadataData,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalArtistMetadataTable,
              StoredLocalArtistMetadataData>
        ),
        StoredLocalArtistMetadataData,
        PrefetchHooks Function()>;
typedef $$StoredLocalTrackMatchesTableCreateCompanionBuilder
    = StoredLocalTrackMatchesCompanion Function({
  required String providerId,
  required String providerTrackId,
  required String localTrackId,
  required String matchMethod,
  required double confidence,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$StoredLocalTrackMatchesTableUpdateCompanionBuilder
    = StoredLocalTrackMatchesCompanion Function({
  Value<String> providerId,
  Value<String> providerTrackId,
  Value<String> localTrackId,
  Value<String> matchMethod,
  Value<double> confidence,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StoredLocalTrackMatchesTableFilterComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalTrackMatchesTable> {
  $$StoredLocalTrackMatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerTrackId => $composableBuilder(
      column: $table.providerTrackId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localTrackId => $composableBuilder(
      column: $table.localTrackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StoredLocalTrackMatchesTableOrderingComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalTrackMatchesTable> {
  $$StoredLocalTrackMatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerTrackId => $composableBuilder(
      column: $table.providerTrackId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localTrackId => $composableBuilder(
      column: $table.localTrackId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoredLocalTrackMatchesTableAnnotationComposer
    extends Composer<_$MeloDriftDatabase, $StoredLocalTrackMatchesTable> {
  $$StoredLocalTrackMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get providerTrackId => $composableBuilder(
      column: $table.providerTrackId, builder: (column) => column);

  GeneratedColumn<String> get localTrackId => $composableBuilder(
      column: $table.localTrackId, builder: (column) => column);

  GeneratedColumn<String> get matchMethod => $composableBuilder(
      column: $table.matchMethod, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoredLocalTrackMatchesTableTableManager extends RootTableManager<
    _$MeloDriftDatabase,
    $StoredLocalTrackMatchesTable,
    StoredLocalTrackMatche,
    $$StoredLocalTrackMatchesTableFilterComposer,
    $$StoredLocalTrackMatchesTableOrderingComposer,
    $$StoredLocalTrackMatchesTableAnnotationComposer,
    $$StoredLocalTrackMatchesTableCreateCompanionBuilder,
    $$StoredLocalTrackMatchesTableUpdateCompanionBuilder,
    (
      StoredLocalTrackMatche,
      BaseReferences<_$MeloDriftDatabase, $StoredLocalTrackMatchesTable,
          StoredLocalTrackMatche>
    ),
    StoredLocalTrackMatche,
    PrefetchHooks Function()> {
  $$StoredLocalTrackMatchesTableTableManager(
      _$MeloDriftDatabase db, $StoredLocalTrackMatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredLocalTrackMatchesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredLocalTrackMatchesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredLocalTrackMatchesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> providerId = const Value.absent(),
            Value<String> providerTrackId = const Value.absent(),
            Value<String> localTrackId = const Value.absent(),
            Value<String> matchMethod = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalTrackMatchesCompanion(
            providerId: providerId,
            providerTrackId: providerTrackId,
            localTrackId: localTrackId,
            matchMethod: matchMethod,
            confidence: confidence,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            required String providerTrackId,
            required String localTrackId,
            required String matchMethod,
            required double confidence,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoredLocalTrackMatchesCompanion.insert(
            providerId: providerId,
            providerTrackId: providerTrackId,
            localTrackId: localTrackId,
            matchMethod: matchMethod,
            confidence: confidence,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoredLocalTrackMatchesTableProcessedTableManager
    = ProcessedTableManager<
        _$MeloDriftDatabase,
        $StoredLocalTrackMatchesTable,
        StoredLocalTrackMatche,
        $$StoredLocalTrackMatchesTableFilterComposer,
        $$StoredLocalTrackMatchesTableOrderingComposer,
        $$StoredLocalTrackMatchesTableAnnotationComposer,
        $$StoredLocalTrackMatchesTableCreateCompanionBuilder,
        $$StoredLocalTrackMatchesTableUpdateCompanionBuilder,
        (
          StoredLocalTrackMatche,
          BaseReferences<_$MeloDriftDatabase, $StoredLocalTrackMatchesTable,
              StoredLocalTrackMatche>
        ),
        StoredLocalTrackMatche,
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
  $$StoredLocalLibraryRootsTableTableManager get storedLocalLibraryRoots =>
      $$StoredLocalLibraryRootsTableTableManager(
          _db, _db.storedLocalLibraryRoots);
  $$StoredLocalLibraryTracksTableTableManager get storedLocalLibraryTracks =>
      $$StoredLocalLibraryTracksTableTableManager(
          _db, _db.storedLocalLibraryTracks);
  $$StoredLocalLibraryFavoritesTableTableManager
      get storedLocalLibraryFavorites =>
          $$StoredLocalLibraryFavoritesTableTableManager(
              _db, _db.storedLocalLibraryFavorites);
  $$StoredLocalArtistMetadataTableTableManager get storedLocalArtistMetadata =>
      $$StoredLocalArtistMetadataTableTableManager(
          _db, _db.storedLocalArtistMetadata);
  $$StoredLocalTrackMatchesTableTableManager get storedLocalTrackMatches =>
      $$StoredLocalTrackMatchesTableTableManager(
          _db, _db.storedLocalTrackMatches);
}
