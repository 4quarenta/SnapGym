import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig has not been initialized.'),
);

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromCompileTime(AppEnvironment environment) {
    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get hasSupabaseConfiguration =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
