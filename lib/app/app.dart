import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/sg_theme.dart';
import 'router/app_router.dart';

class SnapGymApp extends ConsumerWidget {
  const SnapGymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SnapGym',
      debugShowCheckedModeBanner: false,
      theme: SgTheme.light,
      darkTheme: SgTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
