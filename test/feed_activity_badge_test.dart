import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/activity/data/activity_repository.dart';
import 'package:snapgym/features/feed/data/feed_repository.dart';
import 'package:snapgym/features/feed/domain/feed_checkin.dart';
import 'package:snapgym/features/feed/presentation/feed_with_activity_screen.dart';

void main() {
  testWidgets('feed shows unread activity badge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedCheckinsProvider.overrideWith(
            (ref) async => const <FeedCheckin>[],
          ),
          unreadActivityCountProvider.overrideWith((ref) async => 4),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FeedWithActivityScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Atividade: 4 novidades'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('feed hides badge when there is no unread activity', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedCheckinsProvider.overrideWith(
            (ref) async => const <FeedCheckin>[],
          ),
          unreadActivityCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FeedWithActivityScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Atividade'), findsOneWidget);
  });
}
