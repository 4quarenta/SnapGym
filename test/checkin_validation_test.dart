import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/features/checkin/domain/checkin_validation.dart';

void main() {
  test('accepts valid duration', () {
    expect(CheckinValidation.duration('45'), isNull);
  });

  test('rejects duration outside supported range', () {
    expect(CheckinValidation.duration('0'), isNotNull);
    expect(CheckinValidation.duration('721'), isNotNull);
    expect(CheckinValidation.duration('abc'), isNotNull);
  });

  test('limits check-in note to 280 characters', () {
    expect(CheckinValidation.note('a' * 280), isNull);
    expect(CheckinValidation.note('a' * 281), isNotNull);
  });
}
