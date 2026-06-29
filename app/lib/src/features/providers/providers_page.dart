import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
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
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '这里可以模拟启用/禁用来源与登录态变化，验证全部喜欢与本地歌单的降级行为。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8D9BA8),
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
        color: const Color(0xFF10161D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF29313A)),
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
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descriptor.shortDescription ?? descriptor.id.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8D9BA8),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: entry.isEnabled,
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
                    ? const Color(0xFF1D3A33)
                    : const Color(0xFF353123),
                foregroundColor: entry.isEnabled
                    ? const Color(0xFF97E2D4)
                    : const Color(0xFFE1C07A),
              ),
              ProviderBadge(
                label: entry.provider.isAuthenticated ? '已登录' : '未登录',
                backgroundColor: entry.provider.isAuthenticated
                    ? const Color(0xFF1E2B36)
                    : const Color(0xFF332128),
                foregroundColor: entry.provider.isAuthenticated
                    ? const Color(0xFFB7D5F1)
                    : const Color(0xFFF3B5C6),
              ),
              ProviderBadge(
                label: isEligibleFavoriteSource ? '进入全部喜欢' : '不进入全部喜欢',
                backgroundColor: isEligibleFavoriteSource
                    ? const Color(0xFF1F2F1F)
                    : const Color(0xFF252B31),
                foregroundColor: isEligibleFavoriteSource
                    ? const Color(0xFFBCE4A8)
                    : const Color(0xFFB0BEC5),
              ),
              ProviderBadge(
                label: descriptor.status.name,
                backgroundColor: const Color(0xFF232B35),
                foregroundColor: const Color(0xFFB9C5D1),
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
                      color: const Color(0xFF9FB0BF),
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
                Chip(label: Text(capability.label)),
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
