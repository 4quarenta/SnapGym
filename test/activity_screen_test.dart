import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/activity/data/activity_repository.dart';
import 'package:snapgym/features/activity/domain/activity_notification.dart';
import 'package:snapgym/features/activity/presentation/activity_screen.dart';

void main() {
  testWidgets('shows unread activity and social events', (tester) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadActivityCountProvider.overrideWith((ref) async => 2),
          activityNotificationsProvider.overrideWith(
            (ref) async => <ActivityNotification>[
              ActivityNotification(
                id: 'n1',
                kind: ActivityNotificationKind.follow,
                actorId: 'u2',
                actorUsername: 'maria',
                actorDisplayName: 'Maria Silva',
                createdAt: now.subtract(const Duration(minutes: 4)),
              ),
              ActivityNotification(
                id: 'n2',
                kind: ActivityNotificationKind.comment,
                actorId: 'u3',
                actorUsername: 'carlos',
                actorDisplayName: 'Carlos Souza',
                checkinId: 'c1',
                workoutType: 'corrida',
                commentBody: 'Mandou muito bem!',
                createdAt: now.subtract(const Duration(hours: 1)),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: ActivityScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Atividade'), findsOneWidget);
    expect(find.text('2 novidades'), findsOneWidget);
    expect(find.text('Ler todas'), findsOneWidget);
    expect(find.textContaining('Maria Silva'), findsOneWidget);
    expect(find.textContaining('Carlos Souza'), findsOneWidget);
    expect(find.text('“Mandou muito bem!”'), findsOneWidget);
  });
}
