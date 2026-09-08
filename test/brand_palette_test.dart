import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/core/theme/sg_colors.dart';

void main() {
  test('brand colors remain locked to SnapGym v0.1', () {
    expect(SgColors.orange.toARGB32(), 0xFFF06021);
    expect(SgColors.jet.toARGB32(), 0xFF202123);
    expect(SgColors.moonstone.toARGB32(), 0xFF6B9CAA);
  });
}
