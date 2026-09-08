import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ScaffoldWithNavigation extends StatelessWidget {
  const ScaffoldWithNavigation({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.regular.house),
            selectedIcon: PhosphorIcon(PhosphorIcons.fill.house),
            label: 'Início',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.regular.compass),
            selectedIcon: PhosphorIcon(PhosphorIcons.fill.compass),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.regular.camera),
            selectedIcon: PhosphorIcon(PhosphorIcons.fill.camera),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.regular.chartBar),
            selectedIcon: PhosphorIcon(PhosphorIcons.fill.chartBar),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.regular.user),
            selectedIcon: PhosphorIcon(PhosphorIcons.fill.user),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
