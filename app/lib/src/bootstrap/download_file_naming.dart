import 'package:provider_contract/provider_contract.dart';

/// Builds a readable file stem that is safe on Windows, Android, macOS, and
/// Linux. The provider/track id remains the authoritative download identity.
String buildDownloadFileBaseName(SourceTrack track) {
  final artist = _safeFileNamePart(
    track.artists.where((value) => value.trim().isNotEmpty).join(', '),
    fallback: '未知歌手',
  );
  final title = _safeFileNamePart(track.title, fallback: '未知歌曲');
  return _limitFileNameLength('$artist - $title');
}

String _safeFileNamePart(String value, {required String fallback}) {
  var result = value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();
  if (result.isEmpty) result = fallback;

  // Windows treats these names as devices even when an extension is present.
  if (RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$', caseSensitive: false)
      .hasMatch(result)) {
    result = '_$result';
  }
  return result;
}

String _limitFileNameLength(String value) {
  const maxCodePoints = 180;
  final codePoints = value.runes.toList(growable: false);
  if (codePoints.length <= maxCodePoints) return value;
  return String.fromCharCodes(codePoints.take(maxCodePoints)).trimRight();
}
