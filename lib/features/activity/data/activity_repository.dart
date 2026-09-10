import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/activity_notification.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(supabaseClientProvider));
});

final activityNotificationsProvider =
    FutureProvider.autoDispose<List<ActivityNotification>>((ref) {
      return ref.watch(activityRepositoryProvider).list();
    });

final unreadActivityCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(activityRepositoryProvider).unreadCount();
});

class ActivityRepository {
  const ActivityRepository(this._client);

  final SupabaseClient? _client;

  Future<List<ActivityNotification>> list({int limit = 50}) async {
    final response = await _requireClient.rpc<List<dynamic>>(
      'get_activity_notifications',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': 0},
    );

    return response
        .whereType<Map<String, dynamic>>()
        .map(
          (row) =>
              ActivityNotification.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<int> unreadCount() async {
    final response = await _requireClient.rpc<dynamic>(
      'get_unread_activity_count',
    );
    if (response is num) return response.toInt();
    return int.tryParse('$response') ?? 0;
  }

  Future<bool> markRead(String notificationId) async {
    final response = await _requireClient.rpc<dynamic>(
      'mark_activity_notification_read',
      params: <String, dynamic>{'p_notification_id': notificationId},
    );
    return response == true;
  }

  Future<int> markAllRead() async {
    final response = await _requireClient.rpc<dynamic>(
      'mark_all_activity_notifications_read',
    );
    if (response is num) return response.toInt();
    return int.tryParse('$response') ?? 0;
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
