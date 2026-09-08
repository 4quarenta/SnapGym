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
            icon: PhosphorIcon(PhosphorIcons.house()),
            selectedIcon: PhosphorIcon(
              PhosphorIcons.house(PhosphorIconsStyle.fill),
            ),
            label: 'Início',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.compass()),
            selectedIcon: PhosphorIcon(
              PhosphorIcons.compass(PhosphorIconsStyle.fill),
            ),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.camera()),
            selectedIcon: PhosphorIcon(
              PhosphorIcons.camera(PhosphorIconsStyle.fill),
            ),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.chartBar()),
            selectedIcon: PhosphorIcon(
              PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
            ),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIcons.user()),
            selectedIcon: PhosphorIcon(
              PhosphorIcons.user(PhosphorIconsStyle.fill),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
