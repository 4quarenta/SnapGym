import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

final activeChallengesProvider =
    FutureProvider.autoDispose<List<ChallengeSummary>>(
      (ref) => ref.watch(challengeRepositoryProvider).fetchActive(),
    );

final challengeRankingProvider = FutureProvider.autoDispose
    .family<List<ChallengeRankingEntry>, String>((ref, challengeId) {
      return ref.watch(challengeRepositoryProvider).fetchRanking(challengeId);
    });

class ChallengeRepository {
  const ChallengeRepository(this._client, this._authRepository);

  final SupabaseClient? _client;
  final AuthRepository _authRepository;

  Future<List<ChallengeSummary>> fetchActive() async {
    final response = await _requireClient.rpc<List<dynamic>>(
      'get_active_challenges',
      params: const <String, dynamic>{'p_limit': 30},
    );
    return _rows(response).map(ChallengeSummary.fromJson).toList();
  }

  Future<List<ChallengeRankingEntry>> fetchRanking(String challengeId) async {
    final response = await _requireClient.rpc<List<dynamic>>(
      'get_challenge_ranking',
      params: <String, dynamic>{'p_challenge_id': challengeId, 'p_limit': 50},
    );
    return _rows(response).map(ChallengeRankingEntry.fromJson).toList();
  }

  Future<void> setJoined({
    required String challengeId,
    required bool joined,
  }) async {
    final userId = _requireUserId;
    if (joined) {
      await _requireClient.from('challenge_participants').insert(
        <String, dynamic>{'challenge_id': challengeId, 'user_id': userId},
      );
      return;
    }

    await _requireClient
        .from('challenge_participants')
        .delete()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId);
  }

  Future<void> create({
    required String title,
    required String description,
    required DateTime startsOn,
    required DateTime endsOn,
    required int targetDays,
  }) async {
    await _requireClient.rpc<Object?>(
      'create_challenge',
      params: <String, dynamic>{
        'p_title': title.trim(),
        'p_description': description.trim(),
        'p_starts_on': _date(startsOn),
        'p_ends_on': _date(endsOn),
        'p_target_days': targetDays,
      },
    );
  }

  List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String get _requireUserId {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
