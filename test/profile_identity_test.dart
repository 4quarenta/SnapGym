import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/activity/domain/activity_notification.dart';
import 'package:snapgym/features/social/domain/social_profile.dart';

void main() {
  test('social profile parses avatar key', () {
    final profile = SocialProfile.fromJson(<String, dynamic>{
      'id': 'user-1',
      'username': 'ana',
      'display_name': 'Ana Lima',
      'bio': 'Corrida e força',
      'avatar_key': 'user-1/avatar-123.jpg',
      'follower_count': 12,
      'following_count': 8,
      'checkin_count': 19,
      'is_following': true,
    });

    expect(profile.avatarKey, 'user-1/avatar-123.jpg');
    expect(profile.name, 'Ana Lima');
    expect(profile.handle, '@ana');
  });

  test('activity notification parses actor avatar key', () {
    final notification = ActivityNotification.fromJson(<String, dynamic>{
      'notification_id': 'notification-1',
      'kind': 'follow',
      'actor_id': 'user-2',
      'actor_username': 'bruno',
      'actor_display_name': 'Bruno Rocha',
      'actor_avatar_key': 'user-2/avatar-456.jpg',
      'checkin_id': null,
      'workout_type': null,
      'comment_body': null,
      'challenge_id': null,
      'challenge_title': null,
      'read_at': null,
      'created_at': '2026-09-10T12:00:00Z',
    });

    expect(notification.actorAvatarKey, 'user-2/avatar-456.jpg');
    expect(notification.actorName, 'Bruno Rocha');
  });
}
