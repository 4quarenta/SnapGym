import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/activity/domain/activity_notification.dart';

void main() {
  test('parses comment activity notification', () {
    final notification = ActivityNotification.fromJson(<String, dynamic>{
      'notification_id': 'n1',
      'kind': 'comment',
      'actor_id': 'u2',
      'actor_username': 'maria',
      'actor_display_name': 'Maria Silva',
      'checkin_id': 'c1',
      'workout_type': 'corrida',
      'comment_body': 'Treino forte!',
      'challenge_id': null,
      'challenge_title': null,
      'read_at': null,
      'created_at': '2026-09-10T01:00:00Z',
    });

    expect(notification.kind, ActivityNotificationKind.comment);
    expect(notification.actorName, 'Maria Silva');
    expect(notification.commentBody, 'Treino forte!');
    expect(notification.isRead, isFalse);
  });

  test('falls back to username and parses read state', () {
    final notification = ActivityNotification.fromJson(<String, dynamic>{
      'notification_id': 'n2',
      'kind': 'follow',
      'actor_id': 'u3',
      'actor_username': 'carlos',
      'actor_display_name': null,
      'checkin_id': null,
      'workout_type': null,
      'comment_body': null,
      'challenge_id': null,
      'challenge_title': null,
      'read_at': '2026-09-10T01:05:00Z',
      'created_at': '2026-09-10T01:00:00Z',
    });

    expect(notification.actorName, '@carlos');
    expect(notification.isRead, isTrue);
  });
}
