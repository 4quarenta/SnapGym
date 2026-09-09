import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../data/challenge_repository.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';
import 'challenges_section.dart';

class RankingPlaceholderScreen extends ConsumerStatefulWidget {
  const RankingPlaceholderScreen({super.key});

  @override
  ConsumerState<RankingPlaceholderScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingPlaceholderScreen> {
  String _section = 'ranking';
  String _scope = 'following';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyRankingProvider(_scope));
          ref.invalidate(streakProvider);
          ref.invalidate(activeChallengesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            const SgBrand(fontSize: 28),
            const SizedBox(height: SgSpacing.xl),
            Text(
              'Competição',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: SgSpacing.xs),
            const Text('Consistência, disputa e progresso comprovado.'),
            const SizedBox(height: SgSpacing.lg),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment(
                  value: 'ranking',
                  label: Text('Ranking'),
                  icon: Icon(Icons.leaderboard_outlined),
                ),
                ButtonSegment(
                  value: 'challenges',
                  label: Text('Desafios'),
                  icon: Icon(Icons.emoji_events_outlined),
                ),
              ],
              selected: <String>{_section},
              onSelectionChanged: (value) {
                setState(() => _section = value.first);
              },
            ),
            const SizedBox(height: SgSpacing.lg),
            if (_section == 'ranking') _buildRanking(context) else const ChallengesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRanking(BuildContext context) {
    final ranking = ref.watch(weeklyRankingProvider(_scope));
    final streak = ref.watch(streakProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        streak.when(
          data: (value) => Card(
            child: Padding(
              padding: const EdgeInsets.all(SgSpacing.md),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.local_fire_department_rounded, size: 34),
                  const SizedBox(width: SgSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${value.current} dias',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text('Sequência atual · recorde ${value.best} dias'),
                      ],
                    ),
                  ),
                  Icon(
                    value.trainedToday
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                ],
              ),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const Text('Não foi possível carregar sua sequência.'),
        ),
        const SizedBox(height: SgSpacing.lg),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment(
              value: 'following',
              label: Text('Seguindo'),
              icon: Icon(Icons.people_alt_outlined),
            ),
            ButtonSegment(
              value: 'global',
              label: Text('Global'),
              icon: Icon(Icons.public),
            ),
          ],
          selected: <String>{_scope},
          onSelectionChanged: (value) {
            setState(() => _scope = value.first);
          },
        ),
        const SizedBox(height: SgSpacing.lg),
        Text(
          'Esta semana',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: SgSpacing.xs),
        const Text('Dias ativos definem a posição. Check-ins e minutos desempatam.'),
        const SizedBox(height: SgSpacing.sm),
        ranking.when(
          data: (entries) => entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Ainda não há treinos no ranking desta semana.',
                    ),
                  ),
                )
              : Column(
                  children: entries
                      .map((entry) => _RankingTile(entry: entry))
                      .toList(),
                ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não foi possível carregar o ranking.'),
          ),
        ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}º',
    };
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 42,
          child: Center(
            child: Text(
              medal,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        title: Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('@${entry.username} · ${entry.checkins} check-ins'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${entry.activeDays}d',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              '${entry.totalMinutes} min',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
