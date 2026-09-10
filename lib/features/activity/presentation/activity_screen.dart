import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../checkin/domain/workout_type.dart';
import '../data/activity_repository.dart';
import '../domain/activity_notification.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(activityNotificationsProvider);
    final unread = ref.watch(unreadActivityCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividade'),
        actions: <Widget>[
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllRead(ref),
              child: const Text('Ler todas'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityNotificationsProvider);
          ref.invalidate(unreadActivityCountProvider);
          await Future.wait(<Future<dynamic>>[
            ref.read(activityNotificationsProvider.future),
            ref.read(unreadActivityCountProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SgSpacing.lg,
            SgSpacing.md,
            SgSpacing.lg,
            SgSpacing.xxl,
          ),
          children: <Widget>[
            _ActivitySummary(unread: unread),
            const SizedBox(height: SgSpacing.lg),
            notifications.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(SgSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ActivityMessage(
                icon: PhosphorIconsBold.warningCircle,
                title: 'Não foi possível carregar sua atividade.',
                actionLabel: 'Tentar novamente',
                onAction: () => ref.invalidate(activityNotificationsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _ActivityMessage(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Nada por aqui ainda.',
                    subtitle:
                        'Curtidas, comentários, novos seguidores e desafios aparecerão nesta tela.',
                  );
                }

                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: SgSpacing.sm),
                          child: _ActivityTile(item: item),
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

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(activityRepositoryProvider).markAllRead();
    ref.invalidate(activityNotificationsProvider);
    ref.invalidate(unreadActivityCountProvider);
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.lg),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SgColors.orange.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const PhosphorIcon(
                PhosphorIconsBold.bellRinging,
                color: SgColors.orange,
              ),
            ),
            const SizedBox(width: SgSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    unread == 0
                        ? 'Tudo em dia'
                        : '$unread ${unread == 1 ? 'novidade' : 'novidades'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    unread == 0
                        ? 'Você não tem atividades pendentes.'
                        : 'Veja quem interagiu com seus treinos.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SgColors.darkTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.item});

  final ActivityNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _iconFor(item.kind);

    return Card(
      color: item.isRead
          ? null
          : SgColors.orange.withValues(alpha: 0.075),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(SgSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    radius: 23,
                    backgroundColor:
                        SgColors.moonstone.withValues(alpha: 0.18),
                    foregroundColor: SgColors.moonstone,
                    child: Text(
                      item.actorName.characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: PhosphorIcon(icon, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: SgSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: item.actorName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: _messageSuffix(item)),
                        ],
                      ),
                      style: textTheme.bodyLarge,
                    ),
                    if (item.kind == ActivityNotificationKind.comment &&
                        item.commentBody?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: SgSpacing.xs),
                      Text(
                        '“${_shorten(item.commentBody!.trim(), 110)}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: SgColors.darkTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: SgSpacing.xs),
                    Text(
                      _timeAgo(item.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: SgColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: SgSpacing.sm),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: SgColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!item.isRead) {
      await ref.read(activityRepositoryProvider).markRead(item.id);
      ref.invalidate(activityNotificationsProvider);
      ref.invalidate(unreadActivityCountProvider);
    }

    if (!context.mounted) return;

    switch (item.kind) {
      case ActivityNotificationKind.follow:
        context.push('/users/${item.actorId}');
      case ActivityNotificationKind.like:
      case ActivityNotificationKind.comment:
        context.go('/feed');
      case ActivityNotificationKind.challengeJoin:
        context.go('/ranking');
    }
  }
}

String _messageSuffix(ActivityNotification item) {
  switch (item.kind) {
    case ActivityNotificationKind.follow:
      return ' começou a seguir você.';
    case ActivityNotificationKind.like:
      return ' curtiu seu check-in${_workoutLabel(item.workoutType)}.';
    case ActivityNotificationKind.comment:
      return ' comentou no seu check-in${_workoutLabel(item.workoutType)}.';
    case ActivityNotificationKind.challengeJoin:
      final title = item.challengeTitle?.trim();
      return title == null || title.isEmpty
          ? ' entrou no seu desafio.'
          : ' entrou no desafio “$title”.';
  }
}

String _workoutLabel(String? dbValue) {
  if (dbValue == null || dbValue.isEmpty) return '';
  return ' de ${WorkoutType.fromDb(dbValue).label.toLowerCase()}';
}

IconData _iconFor(ActivityNotificationKind kind) {
  switch (kind) {
    case ActivityNotificationKind.follow:
      return PhosphorIconsBold.userPlus;
    case ActivityNotificationKind.like:
      return PhosphorIconsFill.heart;
    case ActivityNotificationKind.comment:
      return PhosphorIconsBold.chatCircle;
    case ActivityNotificationKind.challengeJoin:
      return PhosphorIconsBold.trophy;
  }
}

String _shorten(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 1)}…';
}

String _timeAgo(DateTime value) {
  final now = DateTime.now();
  final difference = now.difference(value.toLocal());

  if (difference.inMinutes < 1) return 'agora';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min';
  if (difference.inHours < 24) return '${difference.inHours} h';
  if (difference.inDays < 7) return '${difference.inDays} d';
  return '${value.toLocal().day.toString().padLeft(2, '0')}/${value.toLocal().month.toString().padLeft(2, '0')}';
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SgSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: <Widget>[
              PhosphorIcon(icon, size: 42, color: SgColors.darkTextSecondary),
              const SizedBox(height: SgSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: SgSpacing.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SgColors.darkTextSecondary,
                      ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: SgSpacing.md),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
