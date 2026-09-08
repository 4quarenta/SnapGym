import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/profile/domain/profile_validation.dart';

void main() {
  test('normalizes usernames', () {
    expect(ProfileValidation.normalizeUsername('  John.Gym  '), 'john.gym');
  });

  test('accepts a valid username', () {
    expect(ProfileValidation.username('john.gym'), isNull);
  });

  test('rejects leading symbols and short usernames', () {
    expect(ProfileValidation.username('.john'), isNotNull);
    expect(ProfileValidation.username('ab'), isNotNull);
  });

  test('limits bio to 160 characters', () {
    final validBio = List<String>.filled(160, 'a').join();
    final invalidBio = List<String>.filled(161, 'a').join();
    expect(ProfileValidation.bio(validBio), isNull);
    expect(ProfileValidation.bio(invalidBio), isNotNull);
  });
}
