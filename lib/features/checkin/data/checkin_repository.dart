import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/media_storage.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/workout_type.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

class CheckinRepository {
  CheckinRepository(this._client, this._authRepository);

  final SupabaseClient? _client;
  final AuthRepository _authRepository;
  final Random _random = Random.secure();

  Future<void> createCheckin({
    required String sourceImagePath,
    required WorkoutType workoutType,
    required int durationMinutes,
    required String note,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    final compressed = await FlutterImageCompress.compressWithFile(
      sourceImagePath,
      quality: 72,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressed == null || compressed.isEmpty) {
      throw StateError('Não foi possível preparar a foto do check-in.');
    }
    if (compressed.lengthInBytes > MediaStorage.maxCheckinPhotoBytes) {
      throw StateError('A foto ficou maior que o limite de 5 MB.');
    }

    final now = DateTime.now().toUtc();
    final objectPath = _buildObjectPath(user.id, now);

    await _requireClient.storage
        .from(MediaStorage.checkinBucket)
        .uploadBinary(
          objectPath,
          compressed,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: '3600',
            upsert: false,
          ),
        );

    await _requireClient.from('checkins').insert(<String, dynamic>{
      'user_id': user.id,
      'workout_type': workoutType.dbValue,
      'duration_minutes': durationMinutes,
      'note': note.trim().isEmpty ? null : note.trim(),
      'photo_path': objectPath,
      'performed_at': now.toIso8601String(),
    });
  }

  String _buildObjectPath(String userId, DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final token = List<String>.generate(
      4,
      (_) => _random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();

    return '$userId/${timestamp.year}/$month/$token.jpg';
  }

  SupabaseClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this build.');
    }
    return client;
  }
}
