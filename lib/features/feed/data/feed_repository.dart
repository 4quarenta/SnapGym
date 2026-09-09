import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/media_storage.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../checkin/domain/workout_type.dart';
import '../domain/feed_checkin.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(supabaseClientProvider));
});

final feedCheckinsProvider = FutureProvider.autoDispose<List<FeedCheckin>>((
  ref,
) async {
  return ref.watch(feedRepositoryProvider).fetchLatest();
});

final profileCheckinsProvider = FutureProvider.autoDispose
    .family<List<FeedCheckin>, String>((ref, userId) async {
      return ref.watch(feedRepositoryProvider).fetchByUser(userId);
    });

class FeedRepository {
  const FeedRepository(this._client);

  final SupabaseClient? _client;

  Future<List<FeedCheckin>> fetchLatest() async {
    final dynamic response = await _requireClient.rpc(
      'get_social_feed',
      params: <String, dynamic>{'p_limit': 30, 'p_offset': 0},
    );
    return _mapRows(_rows(response));
  }

  Future<List<FeedCheckin>> fetchByUser(String userId) async {
    final dynamic response = await _requireClient.rpc(
      'get_profile_checkins',
      params: <String, dynamic>{
        'p_user_id': userId,
        'p_limit': 30,
        'p_offset': 0,
      },
    );
    return _mapRows(_rows(response));
  }

  Future<List<FeedCheckin>> _mapRows(List<Map<String, dynamic>> rows) {
    return Future.wait(
      rows.map((row) async {
        final photoPath = row['photo_path'] as String;
        final signedUrl = await _requireClient.storage
            .from(MediaStorage.checkinBucket)
            .createSignedUrl(photoPath, 3600);

        return FeedCheckin(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          workoutType: WorkoutType.fromDb(row['workout_type'] as String),
          durationMinutes: _asInt(row['duration_minutes']),
          note: row['note'] as String?,
          photoUrl: signedUrl,
          performedAt: DateTime.parse(row['performed_at'] as String).toLocal(),
          username: row['username'] as String?,
          displayName: row['display_name'] as String?,
          likeCount: _asInt(row['like_count']),
          commentCount: _asInt(row['comment_count']),
          likedByMe: row['liked_by_me'] as bool? ?? false,
        );
      }),
    );
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
