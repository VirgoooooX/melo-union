import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../design/melo_tokens.dart';
import '../../widgets/provider_badge.dart';

class ProvidersPage extends ConsumerWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(demoRepositoryProvider);
    final eligible = repository.capabilityMatrix
        .eligibleFavoritesEntries(repository.registry)
        .map((entry) => entry.descriptor.id)
        .toSet();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Provider / 我的',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MeloColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '这里可以模拟启用/禁用来源与登录态变化，验证全部喜欢与本地歌单的降级行为。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MeloColors.textSecondary,
              ),
        ),
        const SizedBox(height: 18),
        for (final entry in repository.providerEntries) ...[
          _ProviderCard(
            entry: entry,
            isEligibleFavoriteSource: eligible.contains(entry.descriptor.id),
          ),
          const SizedBox(height: 14),
        ],
      ],
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
    final repository = ref.watch(demoRepositoryProvider);
    final descriptor = entry.descriptor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeloColors.surface,
        borderRadius: MeloRadii.md,
        border: Border.all(color: MeloColors.border),
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
                    const SizedBox(height: 4),
                    Text(
                      descriptor.shortDescription ?? descriptor.id.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MeloColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: entry.isEnabled,
                activeThumbColor: MeloColors.primary600,
                onChanged: (value) =>
                    repository.setProviderEnabled(descriptor.id, value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => repository.toggleProviderAuthentication(
                descriptor.id,
              ),
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
