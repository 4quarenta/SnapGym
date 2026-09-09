import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

class RankingPlaceholderScreen extends ConsumerStatefulWidget {
  const RankingPlaceholderScreen({super.key});

  @override
  ConsumerState<RankingPlaceholderScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingPlaceholderScreen> {
  String scope = 'following';

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(weeklyRankingProvider(scope));
    final streak = ref.watch(streakProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyRankingProvider(scope));
          ref.invalidate(streakProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            const SgBrand(fontSize: 28),
            const SizedBox(height: SgSpacing.xl),
            Text('Competição', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: SgSpacing.xs),
            Text('Consistência vence. Cada dia treinado conta uma vez.'),
            const SizedBox(height: SgSpacing.lg),
            streak.when(
              data: (value) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(SgSpacing.md),
                  child: Row(children: <Widget>[
                    const Icon(Icons.local_fire_department_rounded, size: 34),
                    const SizedBox(width: SgSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text('${value.current} dias', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Sequência atual · recorde ${value.best} dias'),
                    ])),
                    Icon(value.trainedToday ? Icons.check_circle : Icons.radio_button_unchecked),
                  ]),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Não foi possível carregar sua sequência.'),
            ),
            const SizedBox(height: SgSpacing.lg),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment(value: 'following', label: Text('Seguindo'), icon: Icon(Icons.people_alt_outlined)),
                ButtonSegment(value: 'global', label: Text('Global'), icon: Icon(Icons.public)),
              ],
              selected: <String>{scope},
              onSelectionChanged: (value) => setState(() => scope = value.first),
            ),
            const SizedBox(height: SgSpacing.lg),
            Text('Esta semana', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: SgSpacing.sm),
            ranking.when(
              data: (entries) => entries.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Ainda não há treinos no ranking desta semana.')))
                  : Column(children: entries.map((entry) => _RankingTile(entry: entry)).toList()),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (_, __) => const Padding(padding: EdgeInsets.all(24), child: Text('Não foi possível carregar o ranking.')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry});
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => '${entry.rank}º' };
    return Card(
      child: ListTile(
        leading: SizedBox(width: 42, child: Center(child: Text(medal, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))),
        title: Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('@${entry.username} · ${entry.checkins} check-ins'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          Text('${entry.activeDays}d', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('${entry.totalMinutes} min', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
