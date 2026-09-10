import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_avatar.dart';
import '../../../core/ui/sg_brand.dart';
import '../../social/data/social_repository.dart';
import '../../social/domain/social_profile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(searchSocialProfilesProvider(_query));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(searchSocialProfilesProvider(_query));
          await ref.read(searchSocialProfilesProvider(_query).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            const SgBrand(fontSize: 28),
            const SizedBox(height: SgSpacing.xl),
            Text(
              'Explorar',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: SgSpacing.xs),
            Text(
              'Encontre atletas, acompanhe seus treinos e monte seu feed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SgColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: SgSpacing.lg),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou @usuário',
                prefixIcon: PhosphorIcon(PhosphorIconsBold.magnifyingGlass),
              ),
            ),
            const SizedBox(height: SgSpacing.lg),
            profiles.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(SgSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ExploreError(
                onRetry: () =>
                    ref.invalidate(searchSocialProfilesProvider(_query)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyExplore();
                }
                return Column(
                  children: items
                      .map(
                        (profile) => Padding(
                          padding: const EdgeInsets.only(bottom: SgSpacing.sm),
                          child: _ProfileTile(profile: profile, query: _query),
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

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.profile, required this.query});

  final SocialProfile profile;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/users/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(SgSpacing.md),
          child: Row(
            children: <Widget>[
              SgAvatar(
                label: profile.name,
                avatarKey: profile.avatarKey,
                radius: 24,
              ),
              const SizedBox(width: SgSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (profile.handle != null)
                      Text(
                        profile.handle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SgColors.moonstone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: SgSpacing.xxs),
                    Text(
                      '${profile.followerCount} seguidores • ${profile.checkinCount} treinos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SgColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SgSpacing.sm),
              SizedBox(
                width: 94,
                child: profile.isFollowing
                    ? OutlinedButton(
                        onPressed: () => _toggle(ref, false),
                        child: const Text('Seguindo'),
                      )
                    : FilledButton(
                        onPressed: () => _toggle(ref, true),
                        child: const Text('Seguir'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, bool following) async {
    await ref
        .read(socialRepositoryProvider)
        .setFollowing(userId: profile.id, following: following);
    ref.invalidate(searchSocialProfilesProvider(query));
    ref.invalidate(socialProfileProvider(profile.id));
  }
}

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            PhosphorIcon(PhosphorIconsBold.users, size: 42),
            SizedBox(height: SgSpacing.sm),
            Text('Nenhum atleta encontrado.'),
          ],
        ),
      ),
    );
  }
}

class _ExploreError extends StatelessWidget {
  const _ExploreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            const Text('Não foi possível carregar os atletas.'),
            const SizedBox(height: SgSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
