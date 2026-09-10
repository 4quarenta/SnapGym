import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/updater/data/update_repository.dart';
import 'package:snapgym/features/updater/domain/app_update.dart';
import 'package:snapgym/features/updater/presentation/update_gate.dart';

class _FakeUpdateRepository extends UpdateRepository {
  _FakeUpdateRepository() : super(null, 'dev');

  @override
  Future<AppUpdate?> checkForUpdate() async {
    return AppUpdate(
      platform: 'android',
      channel: 'dev',
      versionName: '0.5.1',
      buildNumber: 7,
      downloadUrl: 'https://example.invalid/update.apk',
      sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      releaseNotes: 'Correção do atualizador.',
      isMandatory: false,
      publishedAt: DateTime.utc(2026, 9, 10),
    );
  }
}

void main() {
  testWidgets(
    'shows update dialog when gate is mounted above the Navigator',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateRepositoryProvider.overrideWithValue(_FakeUpdateRepository()),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('SnapGym')),
            builder: (context, child) => UpdateGate(
              navigatorKey: navigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Atualização disponível'), findsOneWidget);
      expect(find.text('A versão 0.5.1 do SnapGym está disponível.'), findsOneWidget);
      expect(find.text('Atualizar agora'), findsOneWidget);
    },
  );
}
