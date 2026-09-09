import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/social/domain/social_profile.dart';

void main() {
  group('SocialProfile', () {
    test('maps social metrics returned by RPC', () {
      final profile = SocialProfile.fromJson(<String, dynamic>{
        'id': 'user-1',
        'username': 'joao',
        'display_name': 'João',
        'bio': 'Treino todo dia.',
        'follower_count': 12,
        'following_count': 8,
        'checkin_count': 31,
        'is_following': true,
      });

      expect(profile.id, 'user-1');
      expect(profile.name, 'João');
      expect(profile.handle, '@joao');
      expect(profile.followerCount, 12);
      expect(profile.followingCount, 8);
      expect(profile.checkinCount, 31);
      expect(profile.isFollowing, isTrue);
      expect(profile.initial, 'J');
    });

    test('falls back to username when display name is absent', () {
      final profile = SocialProfile.fromJson(<String, dynamic>{
        'id': 'user-2',
        'username': 'snaprunner',
        'display_name': null,
        'bio': null,
        'follower_count': '3',
        'following_count': '4',
        'checkin_count': '5',
        'is_following': false,
      });

      expect(profile.name, '@snaprunner');
      expect(profile.handle, '@snaprunner');
      expect(profile.followerCount, 3);
      expect(profile.checkinCount, 5);
      expect(profile.initial, '@');
    });
  });
}
