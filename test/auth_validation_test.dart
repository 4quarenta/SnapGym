import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/auth/domain/auth_validation.dart';

void main() {
  test('accepts a valid email', () {
    expect(AuthValidation.email('user@example.com'), isNull);
  });

  test('rejects malformed email', () {
    expect(AuthValidation.email('not-an-email'), isNotNull);
  });

  test('requires at least eight password characters', () {
    expect(AuthValidation.password('1234567'), isNotNull);
    expect(AuthValidation.password('12345678'), isNull);
  });
}
