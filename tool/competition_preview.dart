import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgym/core/theme/sg_theme.dart';
import 'package:snapgym/features/activity/data/activity_repository.dart';
import 'package:snapgym/features/activity/domain/activity_notification.dart';
import 'package:snapgym/features/activity/presentation/activity_screen.dart';
import 'package:snapgym/features/ranking/data/challenge_repository.dart';
import 'package:snapgym/features/ranking/data/ranking_repository.dart';
import 'package:snapgym/features/ranking/domain/challenge.dart';
import 'package:snapgym/features/ranking/domain/ranking_entry.dart';
import 'package:snapgym/features/ranking/presentation/ranking_placeholder_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final requestedSection = Uri.base.queryParameters['section'] ?? 'ranking';
  final initialSection = requestedSection == 'challenges' ? 'challenges' : 'ranking';
  final now = DateTime(2026, 9, 10, 20, 30);

  runApp(
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
        unreadActivityCountProvider.overrideWith((ref) async => 3),
        activityNotificationsProvider.overrideWith(
          (ref) async => <ActivityNotification>[
            ActivityNotification(
              id: 'n1',
              kind: ActivityNotificationKind.comment,
              actorId: '2',
              actorUsername: 'maria',
              actorDisplayName: 'Maria Silva',
              checkinId: 'checkin-1',
              workoutType: 'corrida',
              commentBody: 'Esse ritmo ficou muito bom. Bora manter a sequência!',
              createdAt: now.subtract(const Duration(minutes: 8)),
            ),
            ActivityNotification(
              id: 'n2',
              kind: ActivityNotificationKind.like,
              actorId: '3',
              actorUsername: 'carlos',
              actorDisplayName: 'Carlos Souza',
              checkinId: 'checkin-2',
              workoutType: 'musculacao',
              createdAt: now.subtract(const Duration(minutes: 34)),
            ),
            ActivityNotification(
              id: 'n3',
              kind: ActivityNotificationKind.follow,
              actorId: '4',
              actorUsername: 'ana',
              actorDisplayName: 'Ana Lima',
              createdAt: now.subtract(const Duration(hours: 2)),
            ),
            ActivityNotification(
              id: 'n4',
              kind: ActivityNotificationKind.challengeJoin,
              actorId: '5',
              actorUsername: 'pedro',
              actorDisplayName: 'Pedro Alves',
              challengeId: 'challenge-1',
              challengeTitle: '4 dias na semana',
              readAt: now.subtract(const Duration(hours: 3)),
              createdAt: now.subtract(const Duration(hours: 3)),
            ),
          ],
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SgTheme.dark,
        home: requestedSection == 'activity'
            ? const ActivityScreen()
            : Scaffold(
                body: RankingPlaceholderScreen(initialSection: initialSection),
              ),
      ),
    ),
  );
}
