import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/updater/domain/app_update.dart';

void main() {
  test('newer build is detected', () {
    expect(isNewerBuild(currentBuild: 4, candidateBuild: 5), isTrue);
  });

  test('same build is not an update', () {
    expect(isNewerBuild(currentBuild: 5, candidateBuild: 5), isFalse);
  });

  test('older build is not an update', () {
    expect(isNewerBuild(currentBuild: 6, candidateBuild: 5), isFalse);
  });

  test('update model parses metadata', () {
    final update = AppUpdate.fromJson(<String, dynamic>{
      'platform': 'android',
      'channel': 'dev',
      'version_name': '0.4.0',
      'build_number': 7,
      'download_url': 'https://example.test/snapgym.apk',
      'action_url': null,
      'sha256': List<String>.filled(64, 'a').join(),
      'release_notes': 'Teste',
      'is_mandatory': false,
      'published_at': '2026-09-08T22:00:00Z',
    });

    expect(update.buildNumber, 7);
    expect(update.versionName, '0.4.0');
    expect(update.isMandatory, isFalse);
  });
}
