import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_radius.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../../../core/ui/sg_primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../social/data/social_repository.dart';
import '../../social/domain/checkin_comment.dart';
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
            Text(
              'Seu feed',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Seus treinos e os check-ins de quem você segue.',
              style: textTheme.bodyMedium?.copyWith(
                color: SgColors.darkTextSecondary,
              ),
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

class _CheckinCard extends ConsumerWidget {
  const _CheckinCard({required this.item});

  final FeedCheckin item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => context.push('/users/${item.userId}'),
            child: Padding(
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
                const SizedBox(height: SgSpacing.md),
                Row(
                  children: <Widget>[
                    _SocialAction(
                      icon: item.likedByMe
                          ? PhosphorIconsFill.heart
                          : PhosphorIconsRegular.heart,
                      label: '${item.likeCount}',
                      active: item.likedByMe,
                      onPressed: () => _toggleLike(ref),
                    ),
                    const SizedBox(width: SgSpacing.md),
                    _SocialAction(
                      icon: PhosphorIconsRegular.chatCircle,
                      label: '${item.commentCount}',
                      onPressed: () => _openComments(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(WidgetRef ref) async {
    await ref
        .read(socialRepositoryProvider)
        .setLiked(checkinId: item.id, liked: !item.likedByMe);
    ref.invalidate(feedCheckinsProvider);
    ref.invalidate(profileCheckinsProvider(item.userId));
  }

  Future<void> _openComments(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CommentsSheet(checkinId: item.id),
    );
  }
}

class _SocialAction extends StatelessWidget {
  const _SocialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(SgRadius.pill),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SgSpacing.xs,
          vertical: SgSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(
              icon,
              size: 23,
              color: active ? SgColors.orange : null,
            ),
            const SizedBox(width: SgSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: active ? SgColors.orange : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.checkinId});

  final String checkinId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(socialRepositoryProvider)
          .addComment(checkinId: widget.checkinId, body: body);
      _controller.clear();
      ref.invalidate(checkinCommentsProvider(widget.checkinId));
      ref.invalidate(feedCheckinsProvider);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(checkinCommentsProvider(widget.checkinId));
    final ownId = ref.watch(authRepositoryProvider).currentUser?.id;

    return Padding(
      padding: EdgeInsets.only(
        left: SgSpacing.lg,
        right: SgSpacing.lg,
        top: SgSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SgSpacing.lg,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Comentários',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: SgSpacing.md),
            Expanded(
              child: comments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Text('Não foi possível carregar os comentários.'),
                ),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('Seja o primeiro a comentar.'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 20),
                        itemBuilder: (context, index) {
                          final comment = items[index];
                          return _CommentTile(
                            comment: comment,
                            canDelete: ownId == comment.userId,
                            onDelete: () async {
                              await ref
                                  .read(socialRepositoryProvider)
                                  .deleteComment(comment.id);
                              ref.invalidate(
                                checkinCommentsProvider(widget.checkinId),
                              );
                              ref.invalidate(feedCheckinsProvider);
                            },
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: SgSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário...',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: SgSpacing.sm),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  tooltip: 'Enviar',
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const PhosphorIcon(PhosphorIconsBold.paperPlaneTilt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final CheckinComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: SgColors.moonstone.withValues(alpha: 0.18),
          foregroundColor: SgColors.moonstone,
          child: Text(comment.authorName.characters.first.toUpperCase()),
        ),
        const SizedBox(width: SgSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                comment.authorName,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: SgSpacing.xxs),
              Text(comment.body),
              const SizedBox(height: SgSpacing.xxs),
              Text(
                _timeAgo(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SgColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (canDelete)
          IconButton(
            onPressed: onDelete,
            tooltip: 'Excluir comentário',
            icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 19),
          ),
      ],
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
              PhosphorIconsBold.users,
              size: 48,
              color: SgColors.orange,
            ),
            const SizedBox(height: SgSpacing.md),
            Text(
              'Seu feed está começando.',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: SgSpacing.xs),
            const Text(
              'Publique um treino ou siga atletas na aba Explorar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SgSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const PhosphorIcon(PhosphorIconsBold.magnifyingGlass),
              label: const Text('Explorar atletas'),
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
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
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
