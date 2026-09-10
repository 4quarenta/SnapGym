import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/media_storage.dart';
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

  Future<UserProfile> updateAvatar(String sourceImagePath) async {
    final user = _authRepository.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    final previous = await fetch(user.id);
    var compressed = await FlutterImageCompress.compressWithFile(
      sourceImagePath,
      minWidth: 720,
      minHeight: 720,
      quality: 78,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressed == null || compressed.isEmpty) {
      throw StateError('Não foi possível preparar a foto do perfil.');
    }

    if (compressed.lengthInBytes > MediaStorage.maxProfilePhotoBytes) {
      compressed = await FlutterImageCompress.compressWithFile(
        sourceImagePath,
        minWidth: 512,
        minHeight: 512,
        quality: 58,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
    }

    if (compressed == null || compressed.isEmpty) {
      throw StateError('Não foi possível preparar a foto do perfil.');
    }
    if (compressed.lengthInBytes > MediaStorage.maxProfilePhotoBytes) {
      throw StateError('A foto do perfil ficou maior que o limite de 1 MB.');
    }

    final objectPath =
        '${user.id}/avatar-${DateTime.now().toUtc().microsecondsSinceEpoch}.jpg';

    await _requireClient.storage
        .from(MediaStorage.profileBucket)
        .uploadBinary(
          objectPath,
          compressed,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: '86400',
            upsert: false,
          ),
        );

    try {
      final data = await _requireClient
          .from('profiles')
          .update(<String, dynamic>{'avatar_key': objectPath})
          .eq('id', user.id)
          .select()
          .single();

      final oldKey = previous.avatarKey?.trim();
      if (oldKey != null && oldKey.isNotEmpty && oldKey != objectPath) {
        try {
          await _requireClient.storage
              .from(MediaStorage.profileBucket)
              .remove(<String>[oldKey]);
        } catch (_) {
          // The profile already points to the new image. Stale media can be
          // cleaned independently without breaking the user's identity.
        }
      }

      return UserProfile.fromJson(data);
    } catch (_) {
      try {
        await _requireClient.storage
            .from(MediaStorage.profileBucket)
            .remove(<String>[objectPath]);
      } catch (_) {
        // Preserve the original failure; orphan cleanup is best effort.
      }
      rethrow;
    }
  }

  Future<UserProfile> removeAvatar() async {
    final user = _authRepository.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    final current = await fetch(user.id);
    final data = await _requireClient
        .from('profiles')
        .update(<String, dynamic>{'avatar_key': null})
        .eq('id', user.id)
        .select()
        .single();

    final oldKey = current.avatarKey?.trim();
    if (oldKey != null && oldKey.isNotEmpty) {
      try {
        await _requireClient.storage
            .from(MediaStorage.profileBucket)
            .remove(<String>[oldKey]);
      } catch (_) {
        // A stale object is preferable to leaving a broken profile reference.
      }
    }

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
