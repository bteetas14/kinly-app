import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/community/community_screen.dart';
import '../features/community/post_detail_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import 'auth_controller.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final protected = state.matchedLocation == '/notifications' ||
          state.matchedLocation == '/profile';
      if (protected && !auth.isAuthenticated) {
        return '/login';
      }
      if (state.matchedLocation == '/login' && auth.isAuthenticated) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => ExploreScreen(
                  initialQuery: state.uri.queryParameters['q'] ?? ''),
              routes: [
                GoRoute(
                  path: 'products/:id',
                  builder: (context, state) => ProductDetailScreen(
                      productId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityScreen(),
              routes: [
                GoRoute(
                  path: 'posts/:id',
                  builder: (context, state) =>
                      PostDetailScreen(postId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Community'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Notifications'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
