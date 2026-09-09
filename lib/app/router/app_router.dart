import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_router_notifier.dart';
import '../../features/auth/presentation/backend_configuration_screen.dart';
import '../../features/auth/presentation/check_email_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_profile_screen.dart';
import '../../features/ranking/presentation/ranking_placeholder_screen.dart';
import 'scaffold_with_navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth/');

      if (!auth.isConfigured) {
        return location == '/configuration' ? null : '/configuration';
      }

      if (!auth.isSignedIn) {
        return isAuthRoute ? null : '/auth/login';
      }

      if (isAuthRoute || location == '/configuration') {
        return '/feed';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/configuration',
        builder: (context, state) => const BackendConfigurationScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/check-email',
        builder: (context, state) =>
            CheckEmailScreen(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: '/users/:userId',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavigation(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/checkin',
                builder: (context, state) => const CheckinScreen(),
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
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
