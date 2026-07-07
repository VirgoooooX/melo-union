import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/melo_tokens.dart';

final meloShellAccentProviderIdProvider = StateProvider<String>((ref) => 'all');

const _meloBrandAccent = Color(0xFF14BBA6);

String normalizeMeloShellAccentProviderId(String providerId) {
  final id = providerId.trim().toLowerCase();
  if (id.isEmpty ||
      id == 'all' ||
      id == 'local' ||
      id == 'more' ||
      id == 'recommendations') {
    return 'all';
  }
  return id;
}

Color meloAccentColorForProvider(String providerId) {
  final id = normalizeMeloShellAccentProviderId(providerId);
  if (id == 'all') {
    return _meloBrandAccent;
  }
  if (id == 'netease_cloud_music' ||
      id.contains('aurora') ||
      id.contains('netease')) {
    return MeloColors.neteaseForeground;
  }
  if (id == 'qq_music' || id.contains('beacon') || id.contains('qq')) {
    return const Color(0xFFFAC800);
  }
  if (id == 'kugou' || id.contains('kugou')) {
    return MeloColors.kugouForeground;
  }
  return _meloBrandAccent;
}

Color meloShellTint(String providerId, double strength) => Color.lerp(
      MeloColors.canvasSoft,
      meloAccentColorForProvider(providerId),
      strength,
    )!;

BoxDecoration meloShellGradientDecoration(
  String providerId, {
  BorderRadiusGeometry? borderRadius,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        meloShellTint(providerId, 0.20),
        meloShellTint(providerId, 0.13),
        meloShellTint(providerId, 0.07),
        Color.lerp(
          MeloColors.canvas,
          meloAccentColorForProvider(providerId),
          0.006,
        )!,
      ],
      stops: const [0, 0.30, 0.68, 1],
    ),
    borderRadius: borderRadius,
  );
}

Color meloShellChromeColor(double alpha) =>
    MeloColors.surface.withValues(alpha: alpha);

class MeloShellAccentScope extends ConsumerStatefulWidget {
  const MeloShellAccentScope({
    required this.providerId,
    required this.child,
    super.key,
  });

  final String providerId;
  final Widget child;

  @override
  ConsumerState<MeloShellAccentScope> createState() =>
      _MeloShellAccentScopeState();
}

class _MeloShellAccentScopeState extends ConsumerState<MeloShellAccentScope> {
  String? _lastSyncedProviderId;

  @override
  void initState() {
    super.initState();
    _syncAccent(widget.providerId);
  }

  @override
  void didUpdateWidget(covariant MeloShellAccentScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) {
      _syncAccent(widget.providerId);
    }
  }

  void _syncAccent(String providerId) {
    final normalized = normalizeMeloShellAccentProviderId(providerId);
    if (_lastSyncedProviderId == normalized) return;
    _lastSyncedProviderId = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(meloShellAccentProviderIdProvider);
      if (current != normalized) {
        ref.read(meloShellAccentProviderIdProvider.notifier).state = normalized;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
