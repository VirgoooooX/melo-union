import 'dart:convert';
import 'dart:io';

import 'melo_data_snapshot.dart';
import 'melo_json_codec.dart';
import 'melo_snapshot_store.dart';

final class JsonMeloDataStore implements MeloSnapshotStore {
  JsonMeloDataStore({
    required this.file,
    MeloJsonCodec codec = const MeloJsonCodec(),
  }) : _codec = codec;

  final File file;
  final MeloJsonCodec _codec;

  @override
  Future<MeloDataSnapshot?> read() async {
    if (!await file.exists()) {
      return null;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Melo data snapshot must be a JSON object.');
    }
    return _codec.decodeSnapshot(decoded);
  }

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file
        .writeAsString('${encoder.convert(_codec.encodeSnapshot(snapshot))}\n');
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
