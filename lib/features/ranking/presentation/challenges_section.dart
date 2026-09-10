import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sg_spacing.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge.dart';

class ChallengesSection extends ConsumerStatefulWidget {
  const ChallengesSection({super.key});

  @override
  ConsumerState<ChallengesSection> createState() => _ChallengesSectionState();
}

class _ChallengesSectionState extends ConsumerState<ChallengesSection> {
  final Set<String> _busy = <String>{};

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(activeChallengesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Desafios ativos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Criar'),
            ),
          ],
        ),
        const SizedBox(height: SgSpacing.sm),
        challenges.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Nenhum desafio ativo. Crie o primeiro.'),
                ),
              );
            }
            return Column(
              children: items
                  .map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: SgSpacing.sm),
                      child: _ChallengeCard(
                        challenge: challenge,
                        busy: _busy.contains(challenge.id),
                        onToggleJoin: () => _toggleJoin(challenge),
                        onOpen: () => _openRanking(challenge),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(SgSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(SgSpacing.lg),
            child: Text('Não foi possível carregar os desafios.'),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleJoin(ChallengeSummary challenge) async {
    if (_busy.contains(challenge.id)) return;
    setState(() => _busy.add(challenge.id));
    try {
      await ref
          .read(challengeRepositoryProvider)
          .setJoined(challengeId: challenge.id, joined: !challenge.joined);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(challengeRankingProvider(challenge.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o desafio.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy.remove(challenge.id));
      }
    }
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateChallengeSheet(),
    );
    if (created == true) {
      ref.invalidate(activeChallengesProvider);
    }
  }

  void _openRanking(ChallengeSummary challenge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChallengeRankingSheet(challenge: challenge),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.busy,
    required this.onToggleJoin,
    required this.onOpen,
  });

  final ChallengeSummary challenge;
  final bool busy;
  final VoidCallback onToggleJoin;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(SgSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text('@${challenge.creatorUsername}'),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_outlined),
                ],
              ),
              if (challenge.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: SgSpacing.sm),
                Text(
                  challenge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: SgSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${challenge.progressDays}/${challenge.targetDays} dias',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${challenge.participantCount} participantes'),
                ],
              ),
              const SizedBox(height: SgSpacing.xs),
              LinearProgressIndicator(
                value: challenge.joined ? challenge.progress : 0,
              ),
              const SizedBox(height: SgSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${_date(challenge.startsOn)} → ${_date(challenge.endsOn)}',
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: busy ? null : onToggleJoin,
                    child: Text(challenge.joined ? 'Sair' : 'Participar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeRankingSheet extends ConsumerWidget {
  const _ChallengeRankingSheet({required this.challenge});

  final ChallengeSummary challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(challengeRankingProvider(challenge.id));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SgSpacing.lg,
          right: SgSpacing.lg,
          bottom: SgSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                challenge.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: SgSpacing.xs),
              Text(
                'Meta: ${challenge.targetDays} dias · ${challenge.participantCount} participantes',
              ),
              const SizedBox(height: SgSpacing.lg),
              Expanded(
                child: ranking.when(
                  data: (items) => items.isEmpty
                      ? const Center(child: Text('Ainda não há participantes.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final position = switch (item.rank) {
                              1 => '🥇',
                              2 => '🥈',
                              3 => '🥉',
                              _ => '${item.rank}º',
                            };
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(
                                width: 40,
                                child: Center(child: Text(position)),
                              ),
                              title: Text(
                                item.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '@${item.username} · ${item.checkins} check-ins',
                              ),
                              trailing: Text(
                                '${item.activeDays}d',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Não foi possível carregar o ranking.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet();

  @override
  ConsumerState<_CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  int _targetDays = 4;
  late DateTime _startsOn;
  late DateTime _endsOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startsOn = DateTime(now.year, now.month, now.day);
    _endsOn = _startsOn.add(const Duration(days: 6));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxTarget = _endsOn.difference(_startsOn).inDays + 1;
    if (_targetDays > maxTarget) _targetDays = maxTarget;
    return Padding(
      padding: EdgeInsets.only(
        left: SgSpacing.lg,
        right: SgSpacing.lg,
        bottom: SgSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Novo desafio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: SgSpacing.lg),
              TextFormField(
                controller: _title,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Nome do desafio'),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 3 ? 'Use pelo menos 3 caracteres.' : null;
                },
              ),
              TextFormField(
                controller: _description,
                maxLength: 280,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
              const SizedBox(height: SgSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Início ${_date(_startsOn)}'),
                    ),
                  ),
                  const SizedBox(width: SgSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Fim ${_date(_endsOn)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SgSpacing.md),
              Text(
                'Meta: $_targetDays dias',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: _targetDays.toDouble(),
                min: 1,
                max: maxTarget.clamp(1, 31).toDouble(),
                divisions: maxTarget.clamp(1, 31) - 1 == 0
                    ? null
                    : maxTarget.clamp(1, 31) - 1,
                label: '$_targetDays dias',
                onChanged: (value) {
                  setState(() => _targetDays = value.round());
                },
              ),
              const SizedBox(height: SgSpacing.md),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.emoji_events_outlined),
                label: const Text('Criar desafio'),
              ),
              const SizedBox(height: SgSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startsOn,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startsOn = selected;
      if (_endsOn.isBefore(_startsOn)) {
        _endsOn = _startsOn.add(const Duration(days: 6));
      }
    });
  }

  Future<void> _pickEnd() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endsOn.isBefore(_startsOn) ? _startsOn : _endsOn,
      firstDate: _startsOn,
      lastDate: _startsOn.add(const Duration(days: 90)),
    );
    if (selected == null || !mounted) return;
    setState(() => _endsOn = selected);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .create(
            title: _title.text,
            description: _description.text,
            startsOn: _startsOn,
            endsOn: _endsOn,
            targetDays: _targetDays,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar o desafio.')),
      );
    }
  }
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}
