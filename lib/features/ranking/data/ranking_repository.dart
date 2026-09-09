import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(supabaseClientProvider));
});

final weeklyRankingProvider = FutureProvider.autoDispose
    .family<List<RankingEntry>, String>((ref, scope) {
  return ref.watch(rankingRepositoryProvider).weekly(scope: scope);
});

final streakProvider = FutureProvider.autoDispose<StreakSummary>((ref) {
  return ref.watch(rankingRepositoryProvider).streak();
});

class RankingRepository {
  const RankingRepository(this._client);
  final SupabaseClient? _client;

  Future<List<RankingEntry>> weekly({String scope = 'following'}) async {
    final response = await _requireClient.rpc<List<dynamic>>(
      'get_weekly_ranking',
      params: <String, dynamic>{'p_scope': scope, 'p_limit': 50},
    );
    return _rows(response).map(RankingEntry.fromJson).toList();
  }

  Future<StreakSummary> streak() async {
    final response = await _requireClient.rpc<List<dynamic>>('get_my_streak');
    final rows = _rows(response);
    if (rows.isEmpty) {
      return const StreakSummary(current: 0, best: 0, trainedToday: false);
    }
    return StreakSummary.fromJson(rows.first);
  }

  List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List<dynamic>) return const <Map<String, dynamic>>[];
    return response
        .whereType<Map<String, dynamic>>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured for this build.');
    return client;
  }
}
