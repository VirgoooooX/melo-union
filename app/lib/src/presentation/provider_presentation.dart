import 'package:flutter/material.dart';
import 'package:provider_contract/provider_contract.dart';

import '../design/melo_tokens.dart';

final class MeloProviderPresentation {
  const MeloProviderPresentation({
    required this.shortName,
    required this.fullName,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String shortName;
  final String fullName;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}

MeloProviderPresentation meloProviderPresentation(
  ProviderId id, {
  String? displayName,
}) {
  final value = id.value.toLowerCase();
  if (value == 'netease_cloud_music' || value.contains('aurora')) {
    return const MeloProviderPresentation(
      shortName: '网易云',
      fullName: '网易云音乐',
      backgroundColor: MeloColors.neteaseBackground,
      foregroundColor: MeloColors.neteaseForeground,
      icon: Icons.cloud_queue_rounded,
    );
  }
  if (value == 'qq_music' || value.contains('beacon')) {
    return const MeloProviderPresentation(
      shortName: 'QQ音乐',
      fullName: 'QQ音乐',
      backgroundColor: MeloColors.qqBackground,
      foregroundColor: MeloColors.qqForeground,
      icon: Icons.music_note_rounded,
    );
  }
  if (value.contains('local')) {
    return MeloProviderPresentation(
      shortName: displayName ?? '本地',
      fullName: displayName ?? '本地音乐',
      backgroundColor: MeloColors.localBackground,
      foregroundColor: MeloColors.localForeground,
      icon: Icons.folder_rounded,
    );
  }
  if (value == 'compass_catalog' || value.contains('compass')) {
    return const MeloProviderPresentation(
      shortName: 'Compass',
      fullName: 'Compass Catalog',
      backgroundColor: Color(0xFFEAF8F6),
      foregroundColor: Color(0xFF087C76),
      icon: Icons.explore_rounded,
    );
  }
  final label = displayName ?? id.value;
  return MeloProviderPresentation(
    shortName: label,
    fullName: label,
    backgroundColor: MeloColors.surfaceMuted,
    foregroundColor: MeloColors.textSecondary,
    icon: Icons.library_music_rounded,
  );
}
