import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_logo_mark.dart';
import '../../widgets/provider_badge.dart';

class ProvidersPage extends ConsumerWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(
      demoRepositoryProvider.select(
        (r) => r.capabilityMatrix
            .eligibleFavoritesEntries(r.registry)
            .map((entry) => entry.descriptor.id)
            .toSet(),
      ),
    );
    final providerEntries = ref.watch(
      demoRepositoryProvider.select((r) => r.providerEntries),
    );

    return ListView(
      padding: const EdgeInsets.all(MeloSpacing.lg),
      children: [
        Row(
          children: [
            const _ProvidersBrandLogo(),
            const SizedBox(width: MeloSpacing.sm),
            Expanded(
              child: Text(
                'Provider / 我的',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: MeloColors.textPrimary,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MeloSpacing.xs),
        Text(
          '这里可以模拟启用/禁用来源与登录态变化，验证全部喜欢与本地歌单的降级行为。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: MeloSpacing.lg),
        for (final entry in providerEntries) ...[
          _ProviderCard(
            entry: entry,
            isEligibleFavoriteSource: eligible.contains(entry.descriptor.id),
          ),
          const SizedBox(height: MeloSpacing.sm),
        ],
      ],
    );
  }
}

class _ProvidersBrandLogo extends StatelessWidget {
  const _ProvidersBrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: MeloColors.primary600,
        borderRadius: MeloRadii.md,
        boxShadow: [
          BoxShadow(
            color: MeloColors.primary600.withValues(alpha: .22),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: MeloLogoMark(size: 28, semanticLabel: null),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({
    required this.entry,
    required this.isEligibleFavoriteSource,
  });

  final ProviderRegistryEntry entry;
  final bool isEligibleFavoriteSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(demoRepositoryProvider);
    final descriptor = entry.descriptor;

    return Container(
      padding: const EdgeInsets.all(MeloSpacing.md),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
        boxShadow: MeloShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptor.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: MeloColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: MeloSpacing.xxs),
                    Text(
                      descriptor.shortDescription ?? descriptor.id.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              MeloSwitch(
                value: entry.isEnabled,
                onChanged: (value) {
                  repository.setProviderEnabled(descriptor.id, value);
                  ref.invalidate(allFavoritesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: MeloSpacing.sm),
          Wrap(
            spacing: MeloSpacing.xs,
            runSpacing: MeloSpacing.xs,
            children: [
              ProviderBadge(
                label: entry.isEnabled ? '已启用' : '已禁用',
                backgroundColor: entry.isEnabled
                    ? MeloColors.success.withValues(alpha: 0.1)
                    : MeloColors.surfaceMuted,
                foregroundColor: entry.isEnabled
                    ? MeloColors.success
                    : MeloColors.textSecondary,
              ),
              ProviderBadge(
                label: entry.provider.isAuthenticated ? '已登录' : '未登录',
                backgroundColor: entry.provider.isAuthenticated
                    ? MeloColors.primary50
                    : MeloColors.favorite.withValues(alpha: 0.1),
                foregroundColor: entry.provider.isAuthenticated
                    ? MeloColors.primary700
                    : MeloColors.favorite,
              ),
              ProviderBadge(
                label: isEligibleFavoriteSource ? '进入全部喜欢' : '不进入全部喜欢',
                backgroundColor: isEligibleFavoriteSource
                    ? MeloColors.success.withValues(alpha: 0.1)
                    : MeloColors.surfaceMuted,
                foregroundColor: isEligibleFavoriteSource
                    ? MeloColors.success
                    : MeloColors.textSecondary,
              ),
              ProviderBadge(
                label: descriptor.status.name.toUpperCase(),
                backgroundColor: MeloColors.surfaceMuted,
                foregroundColor: MeloColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: MeloSpacing.sm),
          FutureBuilder<ProviderAccountProfile?>(
            future: entry.provider.getProfile(),
            builder: (context, snapshot) {
              final accountLine = switch (snapshot.connectionState) {
                ConnectionState.done when snapshot.hasData =>
                  '账号：${snapshot.data!.displayName}',
                ConnectionState.done when snapshot.hasError =>
                  '账号：${snapshot.error}',
                _ => descriptor.supports(ProviderCapability.authenticate)
                    ? '账号：读取中'
                    : '账号：无需登录',
              };
              return Text(
                accountLine,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MeloColors.textPrimary,
                    ),
              );
            },
          ),
          const SizedBox(height: MeloSpacing.sm),
          Wrap(
            spacing: MeloSpacing.xs,
            runSpacing: MeloSpacing.xs,
            children: [
              for (final capability in descriptor.capabilities)
                Chip(
                  label: Text(
                    capability.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: MeloColors.surfaceMuted,
                  side: const BorderSide(color: MeloColors.border),
                ),
            ],
          ),
          if (descriptor.supports(ProviderCapability.authenticate)) ...[
            const SizedBox(height: MeloSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                repository.toggleProviderAuthentication(
                  descriptor.id,
                );
                ref.invalidate(allFavoritesProvider);
              },
              icon: Icon(
                entry.provider.isAuthenticated ? Icons.logout : Icons.login,
              ),
              label: Text(
                entry.provider.isAuthenticated ? '模拟退出' : '模拟登录',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
