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
import '../features/products/brand_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import 'auth_controller.dart';
import 'kinly_brand.dart';
import 'responsive.dart';
import 'theme_controller.dart';

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
      GoRoute(
        path: '/explore',
        builder: (context, state) => ExploreScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
          initialCategory: state.uri.queryParameters['category'] ?? '',
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/brands/:id',
        builder: (context, state) =>
            BrandDetailScreen(brandId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen())
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
    final desktop = kinlyIsDesktop(context);
    return Scaffold(
      body: desktop
          ? Row(
              children: [
                _DesktopSidebar(shell: shell),
                const VerticalDivider(width: 1),
                Expanded(child: shell),
              ],
            )
          : shell,
      extendBody: true,
      bottomNavigationBar: desktop ? null : _MobileNavBar(shell: shell),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: colors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(32),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: shell.currentIndex,
            onDestinationSelected: shell.goBranch,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: 'Community'),
              NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: 'Notifications'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: shell.goBranch,
      backgroundColor: colors.surface,
      indicatorColor: colors.primaryContainer,
      extended: true,
      minWidth: 88,
      minExtendedWidth: 224,
      labelType: NavigationRailLabelType.none,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: SizedBox(
          width: 176,
          child: Row(
            children: [
              const KinlyLogo(size: 38),
              const SizedBox(width: 12),
              Text(
                'Kinly',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
      trailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 28, bottom: 18),
            child: ThemeModeToggle(),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum_rounded),
          label: Text('Community'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profile'),
        ),
      ],
    );
  }
}
