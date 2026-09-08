enum AppEnvironment {
  dev,
  staging,
  prod;

  String get label => switch (this) {
    AppEnvironment.dev => 'DEV',
    AppEnvironment.staging => 'STAGING',
    AppEnvironment.prod => 'PROD',
  };

  bool get isProduction => this == AppEnvironment.prod;
}
