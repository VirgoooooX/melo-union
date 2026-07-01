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
        subtitle: '下载入口先保留在导航栏里，离线下载和本地媒体管理会在后续版本实现。',
      ),
    );
  }
}
