import 'package:flutter_test/flutter_test.dart';
import 'package:snapgym/core/config/app_config.dart';
import 'package:snapgym/core/config/app_environment.dart';

void main() {
  test('empty backend configuration is allowed during foundation boot', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
    );

    expect(config.hasSupabaseConfiguration, isFalse);
    expect(config.environment.isProduction, isFalse);
  });

  test('production environment is identified correctly', () {
    expect(AppEnvironment.prod.isProduction, isTrue);
    expect(AppEnvironment.prod.label, 'PROD');
  });
}
