import 'dart:convert';
import 'dart:io';

import 'melo_data_snapshot.dart';
import 'melo_json_codec.dart';

final class JsonMeloDataStore {
  JsonMeloDataStore({
    required this.file,
    MeloJsonCodec codec = const MeloJsonCodec(),
  }) : _codec = codec;

  final File file;
  final MeloJsonCodec _codec;

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

  Future<void> write(MeloDataSnapshot snapshot) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file
        .writeAsString('${encoder.convert(_codec.encodeSnapshot(snapshot))}\n');
  }
}
