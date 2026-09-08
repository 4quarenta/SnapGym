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

class FeedRepository {
  const FeedRepository(this._client);

  final SupabaseClient? _client;

  Future<List<FeedCheckin>> fetchLatest() async {
    final rows = await _requireClient
        .from('checkins')
        .select(
          'id,user_id,workout_type,duration_minutes,note,photo_path,performed_at,profiles!checkins_user_id_fkey(username,display_name)',
        )
        .order('created_at', ascending: false)
        .limit(30);

    return Future.wait(rows.map((row) async {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final photoPath = row['photo_path'] as String;
      final signedUrl = await _requireClient.storage
          .from(MediaStorage.checkinBucket)
          .createSignedUrl(photoPath, 3600);

      return FeedCheckin(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        workoutType: WorkoutType.fromDb(row['workout_type'] as String),
        durationMinutes: row['duration_minutes'] as int,
        note: row['note'] as String?,
        photoUrl: signedUrl,
        performedAt: DateTime.parse(row['performed_at'] as String).toLocal(),
        username: profile?['username'] as String?,
        displayName: profile?['display_name'] as String?,
      );
    }));
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
