import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/profile_validation.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetch(user.id);
});

class ProfileRepository {
  const ProfileRepository(this._client, this._authRepository);

  final SupabaseClient? _client;
  final AuthRepository _authRepository;

  Future<UserProfile> fetch(String userId) async {
    final data = await _requireClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateOwnProfile({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    final data = await _requireClient
        .from('profiles')
        .update(<String, dynamic>{
          'username': ProfileValidation.normalizeUsername(username),
          'display_name': displayName.trim(),
          'bio': bio.trim().isEmpty ? null : bio.trim(),
        })
        .eq('id', user.id)
        .select()
        .single();

    return UserProfile.fromJson(data);
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
