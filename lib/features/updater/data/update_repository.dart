import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/app_update.dart';

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return UpdateRepository(
    ref.watch(supabaseClientProvider),
    config.environment.name,
  );
});

enum UpdateInstallResult { started, permissionRequired }

class UpdateRepository {
  UpdateRepository(this._client, this._channel);

  static const _nativeChannel = MethodChannel('snapgym/updater');

  final SupabaseClient? _client;
  final String _channel;
  final Dio _dio = Dio();

  Future<AppUpdate?> checkForUpdate() async {
    final client = _client;
    if (client == null) return null;

    final platform = _platformName;
    if (platform == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final List<Map<String, dynamic>> rows = await client
        .from('app_versions')
        .select()
        .eq('platform', platform)
        .eq('channel', _channel)
        .eq('is_active', true)
        .order('build_number', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;

    final update = AppUpdate.fromJson(rows.first);
    if (!isNewerBuild(
      currentBuild: currentBuild,
      candidateBuild: update.buildNumber,
    )) {
      return null;
    }

    return update;
  }

  Future<UpdateInstallResult> downloadAndInstallAndroid(
    AppUpdate update, {
    required void Function(double progress) onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK installation is available only on Android.');
    }

    final downloadUrl = update.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw StateError('No APK download URL is configured for this update.');
    }

    final cacheDirectory = await getTemporaryDirectory();
    final updatesDirectory = Directory('${cacheDirectory.path}/updates');
    await updatesDirectory.create(recursive: true);

    final apk = File(
      '${updatesDirectory.path}/snapgym-${update.versionName}-${update.buildNumber}.apk',
    );
    final isGzip = Uri.tryParse(downloadUrl)?.path.toLowerCase().endsWith('.gz') == true;
    final compressed = File('${apk.path}.gz');

    final canReuse = await _isValidExistingFile(apk, update.sha256);
    if (!canReuse) {
      await _deleteIfExists(apk);
      await _deleteIfExists(compressed);

      try {
        final target = isGzip ? compressed : apk;
        final downloadScale = isGzip ? 0.90 : 1.0;

        await _dio.download(
          downloadUrl,
          target.path,
          deleteOnError: true,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              onProgress((received / total) * downloadScale);
            }
          },
        );

        if (isGzip) {
          await _decompressGzip(compressed, apk);
          onProgress(0.95);
          await _deleteIfExists(compressed);
        }

        await _verifySha256(apk, update.sha256);
        onProgress(1);
      } catch (_) {
        await _deleteIfExists(apk);
        await _deleteIfExists(compressed);
        rethrow;
      }
    } else {
      await _deleteIfExists(compressed);
      onProgress(1);
    }

    final canInstall =
        await _nativeChannel.invokeMethod<bool>('canInstallPackages') ?? false;

    if (!canInstall) {
      await _nativeChannel.invokeMethod<void>('openUnknownSourcesSettings');
      return UpdateInstallResult.permissionRequired;
    }

    await _nativeChannel.invokeMethod<void>('installApk', <String, String>{
      'path': apk.path,
    });
    return UpdateInstallResult.started;
  }

  Future<void> _decompressGzip(File compressed, File destination) async {
    final sink = destination.openWrite();
    try {
      await sink.addStream(gzip.decoder.bind(compressed.openRead()));
      await sink.flush();
    } on FormatException {
      throw StateError('O pacote da atualização está corrompido.');
    } finally {
      await sink.close();
    }
  }

  Future<bool> _isValidExistingFile(File file, String? expectedSha256) async {
    if (!await file.exists()) return false;
    if (expectedSha256 == null || expectedSha256.isEmpty) return true;

    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expectedSha256;
  }

  Future<void> _verifySha256(File file, String? expectedSha256) async {
    if (expectedSha256 == null || expectedSha256.isEmpty) return;

    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != expectedSha256) {
      await _deleteIfExists(file);
      throw StateError(
        'A atualização baixada falhou na verificação de integridade.',
      );
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  String? get _platformName {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }
}
