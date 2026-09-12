import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

class ScaffoldWithNavigation extends StatelessWidget {
  const ScaffoldWithNavigation({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/checkin'),
              tooltip: 'Registrar treino',
              child: const PhosphorIcon(PhosphorIconsBold.plus),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            icon: PhosphorIcon(PhosphorIconsRegular.house),
            selectedIcon: PhosphorIcon(PhosphorIconsFill.house),
            label: 'Início',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIconsRegular.chartBar),
            selectedIcon: PhosphorIcon(PhosphorIconsFill.chartBar),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: PhosphorIcon(PhosphorIconsRegular.user),
            selectedIcon: PhosphorIcon(PhosphorIconsFill.user),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
