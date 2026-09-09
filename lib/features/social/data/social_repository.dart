import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/checkin_comment.dart';
import '../domain/social_profile.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

final searchSocialProfilesProvider = FutureProvider.autoDispose
    .family<List<SocialProfile>, String>((ref, query) {
      return ref.watch(socialRepositoryProvider).searchProfiles(query);
    });

final socialProfileProvider = FutureProvider.autoDispose
    .family<SocialProfile?, String>((ref, userId) {
      return ref.watch(socialRepositoryProvider).fetchProfile(userId);
    });

final checkinCommentsProvider = FutureProvider.autoDispose
    .family<List<CheckinComment>, String>((ref, checkinId) {
      return ref.watch(socialRepositoryProvider).fetchComments(checkinId);
    });

class SocialRepository {
  const SocialRepository(this._client, this._authRepository);

  final SupabaseClient? _client;
  final AuthRepository _authRepository;

  Future<List<SocialProfile>> searchProfiles(String query) async {
    final dynamic response = await _requireClient.rpc(
      'search_social_profiles',
      params: <String, dynamic>{
        'p_query': query.trim(),
        'p_limit': 30,
      },
    );
    return _rows(response).map(SocialProfile.fromJson).toList();
  }

  Future<SocialProfile?> fetchProfile(String userId) async {
    final dynamic response = await _requireClient.rpc(
      'get_social_profile',
      params: <String, dynamic>{'p_user_id': userId},
    );
    final rows = _rows(response);
    if (rows.isEmpty) return null;
    return SocialProfile.fromJson(rows.first);
  }

  Future<void> setFollowing({
    required String userId,
    required bool following,
  }) async {
    final ownId = _requireUserId;
    if (ownId == userId) return;

    if (following) {
      await _requireClient.from('social_follows').insert(<String, dynamic>{
        'follower_id': ownId,
        'following_id': userId,
      });
      return;
    }

    await _requireClient
        .from('social_follows')
        .delete()
        .eq('follower_id', ownId)
        .eq('following_id', userId);
  }

  Future<void> setLiked({
    required String checkinId,
    required bool liked,
  }) async {
    final ownId = _requireUserId;
    if (liked) {
      await _requireClient.from('checkin_likes').insert(<String, dynamic>{
        'checkin_id': checkinId,
        'user_id': ownId,
      });
      return;
    }

    await _requireClient
        .from('checkin_likes')
        .delete()
        .eq('checkin_id', checkinId)
        .eq('user_id', ownId);
  }

  Future<List<CheckinComment>> fetchComments(String checkinId) async {
    final rows = await _requireClient
        .from('checkin_comments')
        .select(
          'id,checkin_id,user_id,body,created_at,profiles!checkin_comments_user_id_fkey(username,display_name)',
        )
        .eq('checkin_id', checkinId)
        .order('created_at', ascending: true);

    return rows.map(CheckinComment.fromJson).toList();
  }

  Future<void> addComment({
    required String checkinId,
    required String body,
  }) async {
    final normalized = body.trim();
    if (normalized.isEmpty || normalized.length > 500) {
      throw ArgumentError('O comentário deve ter entre 1 e 500 caracteres.');
    }

    await _requireClient.from('checkin_comments').insert(<String, dynamic>{
      'checkin_id': checkinId,
      'user_id': _requireUserId,
      'body': normalized,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _requireClient
        .from('checkin_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', _requireUserId);
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String get _requireUserId {
    final user = _authRepository.currentUser;
    if (user == null) throw StateError('No authenticated user.');
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
