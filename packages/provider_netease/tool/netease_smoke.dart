import 'package:provider_netease/provider_netease.dart';

Future<void> main(List<String> args) async {
  final query = args.isEmpty ? '孤勇者' : args.join(' ');
  final provider = NeteaseMusicProvider();
  final results = await provider.search(query);
  if (results.isEmpty) {
    throw StateError('NetEase search returned no results for "$query".');
  }
  final first = results.first;
  print('${first.ref.providerId.value}:${first.ref.trackId}:${first.title}');
}
