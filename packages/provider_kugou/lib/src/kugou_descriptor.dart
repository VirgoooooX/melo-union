import 'package:provider_contract/provider_contract.dart';

final kugouProviderId = ProviderId('kugou');

final kugouDescriptor = ProviderDescriptor(
  id: kugouProviderId,
  displayName: '酷狗音乐',
  capabilities: const {
    ProviderCapability.authenticate,
    ProviderCapability.readFavorites,
    ProviderCapability.writeFavorites,
    ProviderCapability.readUserPlaylists,
    ProviderCapability.readDailyRecommendations,
    ProviderCapability.readCharts,
    ProviderCapability.search,
    ProviderCapability.resolvePlayback,
    ProviderCapability.resolveDownload,
    ProviderCapability.lyrics,
    ProviderCapability.artwork,
  },
  status: ProviderStatus.experimental,
  shortDescription: '酷狗音乐 Provider 接入测试中，已开放收藏、搜索、播放、下载与歌词能力。',
);
