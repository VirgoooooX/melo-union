import 'package:flutter/material.dart';

import '../../widgets/melo_components.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: MeloEmptyState(
        icon: Icons.download_done_outlined,
        title: '暂不提供下载功能',
        subtitle: '当前版本先专注在线播放、歌单和收藏；离线下载入口已暂时收起。',
      ),
    );
  }
}
