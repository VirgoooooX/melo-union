import 'package:provider_contract/provider_contract.dart';

enum KugouMediaUse {
  playback,
  download,
}

final class KugouMediaResolution {
  const KugouMediaResolution({
    required this.url,
    required this.quality,
    required this.format,
    required this.fileSize,
    required this.expiresAt,
    required this.headers,
  });

  final Uri url;
  final AudioQuality quality;
  final String format;
  final int fileSize;
  final DateTime expiresAt;
  final Map<String, String> headers;
}
