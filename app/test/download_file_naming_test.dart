import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/download_file_naming.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  SourceTrack track({required String title, required List<String> artists}) =>
      SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('netease_cloud_music'),
          trackId: '123',
        ),
        title: title,
        artists: artists,
        duration: Duration.zero,
        isFavorited: false,
        isDownloadable: true,
      );

  test('uses artist - title for download names', () {
    expect(
      buildDownloadFileBaseName(
        track(title: '月亮照山川', artists: const ['王挣亮']),
      ),
      '王挣亮 - 月亮照山川',
    );
  });

  test('sanitizes cross-platform forbidden characters', () {
    expect(
      buildDownloadFileBaseName(
        track(title: '歌:曲?/名.', artists: const ['歌手<一>', '歌手|二']),
      ),
      '歌手 一 , 歌手 二 - 歌 曲 名',
    );
  });

  test('uses readable fallbacks for missing metadata', () {
    expect(
      buildDownloadFileBaseName(track(title: ' ', artists: const [])),
      '未知歌手 - 未知歌曲',
    );
  });
}
