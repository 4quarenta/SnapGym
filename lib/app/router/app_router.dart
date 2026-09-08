import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/checkin/presentation/checkin_placeholder_screen.dart';
import '../../features/explore/presentation/explore_placeholder_screen.dart';
import '../../features/feed/presentation/feed_placeholder_screen.dart';
import '../../features/profile/presentation/profile_placeholder_screen.dart';
import '../../features/ranking/presentation/ranking_placeholder_screen.dart';
import 'scaffold_with_navigation.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/feed',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavigation(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExplorePlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/checkin',
                builder: (context, state) => const CheckinPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/ranking',
                builder: (context, state) => const RankingPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
