import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/domain/feed_checkin.dart';
import '../../social/data/social_repository.dart';
import '../../social/domain/social_profile.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(socialProfileProvider(userId));
    final checkins = ref.watch(profileCheckinsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(socialProfileProvider(userId));
          ref.invalidate(profileCheckinsProvider(userId));
          await Future.wait(<Future<dynamic>>[
            ref.read(socialProfileProvider(userId).future),
            ref.read(profileCheckinsProvider(userId).future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            profile.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(SgSpacing.xxxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => const _ProfileMessage(
                message: 'Não foi possível carregar este perfil.',
              ),
              data: (value) => value == null
                  ? const _ProfileMessage(message: 'Perfil não encontrado.')
                  : _ProfileHeader(profile: value),
            ),
            const SizedBox(height: SgSpacing.xl),
            Text(
              'Treinos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: SgSpacing.md),
            checkins.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const _ProfileMessage(
                message: 'Não foi possível carregar os treinos.',
              ),
              data: (items) => items.isEmpty
                  ? const _ProfileMessage(
                      message: 'Este atleta ainda não publicou treinos.',
                    )
                  : Column(
                      children: items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: SgSpacing.md,
                              ),
                              child: _WorkoutHistoryCard(item: item),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final SocialProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final isOwnProfile = currentUser?.id == profile.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            SgAvatar(
              label: profile.name,
              avatarKey: profile.avatarKey,
              radius: 44,
            ),
            const SizedBox(height: SgSpacing.md),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (profile.handle != null) ...<Widget>[
              const SizedBox(height: SgSpacing.xxs),
              Text(
                profile.handle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SgColors.moonstone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (profile.bio?.trim().isNotEmpty == true) ...<Widget>[
              const SizedBox(height: SgSpacing.md),
              Text(profile.bio!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: SgSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _Stat(value: profile.checkinCount, label: 'treinos'),
                _Stat(value: profile.followerCount, label: 'seguidores'),
                _Stat(value: profile.followingCount, label: 'seguindo'),
              ],
            ),
            const SizedBox(height: SgSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: isOwnProfile
                  ? OutlinedButton(
                      onPressed: () => context.go('/profile'),
                      child: const Text('Meu perfil'),
                    )
                  : profile.isFollowing
                  ? OutlinedButton.icon(
                      onPressed: () => _setFollowing(ref, false),
                      icon: const PhosphorIcon(PhosphorIconsBold.userMinus),
                      label: const Text('Seguindo'),
                    )
                  : FilledButton.icon(
                      onPressed: () => _setFollowing(ref, true),
                      icon: const PhosphorIcon(PhosphorIconsBold.userPlus),
                      label: const Text('Seguir'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFollowing(WidgetRef ref, bool following) async {
    await ref
        .read(socialRepositoryProvider)
        .setFollowing(userId: profile.id, following: following);
    ref.invalidate(socialProfileProvider(profile.id));
    ref.invalidate(searchSocialProfilesProvider(''));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: SgColors.darkTextSecondary),
        ),
      ],
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  const _WorkoutHistoryCard({required this.item});

  final FeedCheckin item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 108,
            height: 108,
            child: Image.network(
              item.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: SgColors.darkSurfaceElevated,
                child: Center(
                  child: PhosphorIcon(PhosphorIconsBold.imageBroken),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(SgSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.workoutType.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: SgSpacing.xxs),
                  Text('${item.durationMinutes} min'),
                  const SizedBox(height: SgSpacing.sm),
                  Text(
                    '${item.likeCount} curtidas • ${item.commentCount} comentários',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SgColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
