import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/core/theme/sg_theme.dart';
import 'package:snapgym/features/ranking/data/challenge_repository.dart';
import 'package:snapgym/features/ranking/data/ranking_repository.dart';
import 'package:snapgym/features/ranking/domain/challenge.dart';
import 'package:snapgym/features/ranking/domain/ranking_entry.dart';
import 'package:snapgym/features/ranking/presentation/ranking_placeholder_screen.dart';

void main() {
  testWidgets('exports competition previews', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final boundaryKey = GlobalKey();
    final now = DateTime(2026, 9, 9);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyRankingProvider('following').overrideWith(
            (ref) async => const <RankingEntry>[
              RankingEntry(
                userId: '1',
                username: 'john',
                displayName: 'John Alleff',
                activeDays: 5,
                checkins: 6,
                totalMinutes: 245,
                rank: 1,
              ),
              RankingEntry(
                userId: '2',
                username: 'maria',
                displayName: 'Maria Silva',
                activeDays: 4,
                checkins: 5,
                totalMinutes: 220,
                rank: 2,
              ),
              RankingEntry(
                userId: '3',
                username: 'carlos',
                displayName: 'Carlos Souza',
                activeDays: 4,
                checkins: 4,
                totalMinutes: 190,
                rank: 3,
              ),
              RankingEntry(
                userId: '4',
                username: 'ana',
                displayName: 'Ana Lima',
                activeDays: 3,
                checkins: 4,
                totalMinutes: 175,
                rank: 4,
              ),
            ],
          ),
          streakProvider.overrideWith(
            (ref) async => const StreakSummary(
              current: 6,
              best: 11,
              trainedToday: true,
            ),
          ),
          activeChallengesProvider.overrideWith(
            (ref) async => <ChallengeSummary>[
              ChallengeSummary(
                id: 'c1',
                title: '4 dias na semana',
                description: 'Treine em quatro dias diferentes até domingo.',
                startsOn: now.subtract(const Duration(days: 2)),
                endsOn: now.add(const Duration(days: 4)),
                targetDays: 4,
                creatorId: '1',
                creatorUsername: 'john',
                participantCount: 18,
                joined: true,
                progressDays: 3,
              ),
              ChallengeSummary(
                id: 'c2',
                title: 'Constância de setembro',
                description: 'Acumule 12 dias ativos durante o mês.',
                startsOn: DateTime(2026, 9),
                endsOn: DateTime(2026, 9, 30),
                targetDays: 12,
                creatorId: '2',
                creatorUsername: 'maria',
                participantCount: 42,
                joined: false,
                progressDays: 0,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SgTheme.dark,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: const RankingPlaceholderScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _savePreview(boundaryKey, 'build/previews/competition-ranking.png');

    await tester.tap(find.text('Desafios').first);
    await tester.pumpAndSettle();
    await _savePreview(boundaryKey, 'build/previews/competition-challenges.png');
  });
}

Future<void> _savePreview(GlobalKey key, String path) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}
