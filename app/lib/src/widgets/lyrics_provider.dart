import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';
import '../bootstrap/demo_repository.dart';

final lyricsProvider = FutureProvider.family<String?, ProviderTrackRef>((ref, trackRef) async {
  final repository = ref.read(demoRepositoryProvider);
  return repository.getLyrics(trackRef);
});
