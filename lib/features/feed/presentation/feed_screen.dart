import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_radius.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../../../core/ui/sg_primary_button.dart';
import '../data/feed_repository.dart';
import '../domain/feed_checkin.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedCheckinsProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedCheckinsProvider);
          await ref.read(feedCheckinsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            const SgBrand(),
            const SizedBox(height: SgSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Treinos da comunidade',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Check-ins recentes de atletas do SnapGym.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: SgColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SgSpacing.lg),
            SgPrimaryButton(
              label: 'Registrar meu treino',
              icon: const PhosphorIcon(PhosphorIconsBold.camera),
              onPressed: () => context.go('/checkin'),
            ),
            const SizedBox(height: SgSpacing.xl),
            feed.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(SgSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _FeedError(
                message: '$error',
                onRetry: () => ref.invalidate(feedCheckinsProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const _EmptyFeed();
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: SgSpacing.lg),
                          child: _CheckinCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({required this.item});

  final FeedCheckin item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(SgSpacing.md),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: SgColors.moonstone.withValues(alpha: 0.18),
                  foregroundColor: SgColors.moonstone,
                  child: Text(item.authorName.characters.first.toUpperCase()),
                ),
                const SizedBox(width: SgSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.authorName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.username != null)
                        Text(
                          '@${item.username}',
                          style: textTheme.bodySmall?.copyWith(
                            color: SgColors.darkTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(item.performedAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: SgColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              item.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: SgColors.darkSurfaceElevated,
                alignment: Alignment.center,
                child: const PhosphorIcon(
                  PhosphorIconsBold.imageBroken,
                  size: 42,
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: SgColors.darkSurfaceElevated,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SgSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: SgSpacing.sm,
                  runSpacing: SgSpacing.xs,
                  children: <Widget>[
                    _StatChip(
                      icon: PhosphorIconsBold.barbell,
                      label: item.workoutType.label,
                    ),
                    _StatChip(
                      icon: PhosphorIconsBold.clock,
                      label: '${item.durationMinutes} min',
                    ),
                  ],
                ),
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: SgSpacing.md),
                  Text(item.note!, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SgSpacing.sm,
        vertical: SgSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SgColors.moonstone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SgRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(icon, size: 16, color: SgColors.moonstone),
          const SizedBox(width: SgSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            const PhosphorIcon(
              PhosphorIconsBold.camera,
              size: 48,
              color: SgColors.orange,
            ),
            const SizedBox(height: SgSpacing.md),
            Text(
              'Ainda não há check-ins.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: SgSpacing.xs),
            const Text(
              'O primeiro treino publicado aparecerá aqui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.lg),
        child: Column(
          children: <Widget>[
            const PhosphorIcon(PhosphorIconsBold.warning, size: 38),
            const SizedBox(height: SgSpacing.sm),
            const Text('Não foi possível carregar o feed.'),
            const SizedBox(height: SgSpacing.xs),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: SgSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'agora';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min';
  if (difference.inHours < 24) return '${difference.inHours} h';
  return '${difference.inDays} d';
}
