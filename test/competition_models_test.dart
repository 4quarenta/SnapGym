import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/ranking/domain/challenge.dart';
import 'package:snapgym/features/ranking/domain/ranking_entry.dart';

void main() {
  group('RankingEntry', () {
    test('parses ranking payload', () {
      final entry = RankingEntry.fromJson(<String, dynamic>{
        'user_id': 'user-1',
        'username': 'runner',
        'display_name': 'Runner One',
        'avatar_key': null,
        'active_days': 4,
        'checkins': 5,
        'total_minutes': 210,
        'rank': 1,
      });

      expect(entry.userId, 'user-1');
      expect(entry.activeDays, 4);
      expect(entry.checkins, 5);
      expect(entry.rank, 1);
    });
  });

  group('StreakSummary', () {
    test('parses streak payload', () {
      final streak = StreakSummary.fromJson(<String, dynamic>{
        'current_streak': 6,
        'best_streak': 11,
        'trained_today': true,
      });

      expect(streak.current, 6);
      expect(streak.best, 11);
      expect(streak.trainedToday, isTrue);
    });
  });

  group('ChallengeSummary', () {
    test('calculates normalized progress', () {
      final challenge = ChallengeSummary.fromJson(<String, dynamic>{
        'challenge_id': 'challenge-1',
        'title': '4 dias na semana',
        'description': 'Treine quatro dias.',
        'starts_on': '2026-09-07',
        'ends_on': '2026-09-13',
        'target_days': 4,
        'creator_id': 'user-1',
        'creator_username': 'runner',
        'participant_count': 10,
        'joined': true,
        'progress_days': 3,
      });

      expect(challenge.progress, .75);
      expect(challenge.joined, isTrue);
      expect(challenge.targetDays, 4);
    });

    test('caps progress at one', () {
      final challenge = ChallengeSummary.fromJson(<String, dynamic>{
        'challenge_id': 'challenge-2',
        'title': 'Meta curta',
        'description': '',
        'starts_on': '2026-09-07',
        'ends_on': '2026-09-13',
        'target_days': 2,
        'creator_id': 'user-1',
        'creator_username': 'runner',
        'participant_count': 3,
        'joined': true,
        'progress_days': 4,
      });

      expect(challenge.progress, 1);
    });
  });
}
