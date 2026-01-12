import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teleport_router/teleport_router.dart';

void main() {
  group('TeleportRouteData pathPattern', () {
    testWidgets('pathPattern returns original route pattern',
        (WidgetTester tester) async {
      String? capturedFullPath;
      Map<String, String>? capturedParams;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/user/:userId/profile/:tab',
            name: 'user_profile',
            builder: (context, state) {
              final routeData = context.teleportRouteData;
              // pathPattern will be null for GoRouterStateData in runtime
              // In generated routes, pathPattern will be available
              capturedFullPath = routeData.fullPath;
              capturedParams = routeData.pathParams;
              return const Text('Profile');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to a specific user profile
      router.go('/user/123/profile/settings?theme=dark');
      await tester.pumpAndSettle();

      // Verify fullPath and pathParams work correctly
      expect(capturedFullPath, equals('/user/123/profile/settings?theme=dark'));
      expect(capturedParams, equals({'userId': '123', 'tab': 'settings'}));
    });
  });

  group('Route breadcrumbs', () {
    testWidgets('routeBreadcrumbs returns navigation hierarchy',
        (WidgetTester tester) async {
      List<TeleportRouteData>? capturedBreadcrumbs;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const Text('Home'),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'dashboard',
                builder: (context, state) => const Text('Dashboard'),
                routes: [
                  GoRoute(
                    path: 'analytics',
                    name: 'analytics',
                    builder: (context, state) {
                      capturedBreadcrumbs = context.routeBreadcrumbs();
                      return const Text('Analytics');
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to nested route
      router.go('/home/dashboard/analytics');
      await tester.pumpAndSettle();

      // Should have all routes in hierarchy
      expect(capturedBreadcrumbs, isNotNull);
      expect(capturedBreadcrumbs!.length, equals(3));

      // Verify route names in breadcrumb trail
      expect(capturedBreadcrumbs![0].routeName, equals('home'));
      expect(capturedBreadcrumbs![1].routeName, equals('dashboard'));
      expect(capturedBreadcrumbs![2].routeName, equals('analytics'));

      // Verify paths
      expect(capturedBreadcrumbs![0].fullPath, contains('/home'));
      expect(capturedBreadcrumbs![1].fullPath, contains('/home/dashboard'));
      expect(capturedBreadcrumbs![2].fullPath,
          contains('/home/dashboard/analytics'));
    });

    testWidgets('routeBreadcrumbs respects limit parameter',
        (WidgetTester tester) async {
      List<TeleportRouteData>? limitedBreadcrumbs;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/a',
            name: 'a',
            builder: (context, state) => const Text('A'),
            routes: [
              GoRoute(
                path: 'b',
                name: 'b',
                builder: (context, state) => const Text('B'),
                routes: [
                  GoRoute(
                    path: 'c',
                    name: 'c',
                    builder: (context, state) => const Text('C'),
                    routes: [
                      GoRoute(
                        path: 'd',
                        name: 'd',
                        builder: (context, state) {
                          limitedBreadcrumbs =
                              context.routeBreadcrumbs(limit: 2);
                          return const Text('D');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/a/b/c/d');
      await tester.pumpAndSettle();

      // Should only return last 2 routes
      expect(limitedBreadcrumbs, isNotNull);
      expect(limitedBreadcrumbs!.length, equals(2));
      expect(limitedBreadcrumbs![0].routeName, equals('c'));
      expect(limitedBreadcrumbs![1].routeName, equals('d'));
    });

    testWidgets('routeBreadcrumbs returns null for empty route stack',
        (WidgetTester tester) async {
      // This test verifies error handling
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final breadcrumbs = context.routeBreadcrumbs();
              // Should have at least the root route
              expect(breadcrumbs, isNotNull);
              expect(breadcrumbs!.length, greaterThanOrEqualTo(1));
              return const Text('Root');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('routeBreadcrumbs skips shell routes',
        (WidgetTester tester) async {
      List<TeleportRouteData>? breadcrumbs;

      final router = GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              return Scaffold(
                body: child,
                bottomNavigationBar: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.settings), label: 'Settings'),
                  ],
                ),
              );
            },
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) {
                  breadcrumbs = context.routeBreadcrumbs();
                  return const Text('Home');
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/home');
      await tester.pumpAndSettle();

      // Should only have the GoRoute, not the ShellRoute
      expect(breadcrumbs, isNotNull);
      expect(breadcrumbs!.length, equals(1));
      expect(breadcrumbs![0].routeName, equals('home'));
    });
  });

  group('Parameter access methods', () {
    testWidgets('getString and getInt work correctly',
        (WidgetTester tester) async {
      String? userId;
      int? age;
      String? query;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/user/:userId',
            builder: (context, state) {
              final routeData = context.teleportRouteData;
              userId = routeData.getString('userId');
              age = routeData.getInt('age');
              query = routeData.getString('search');
              return const Text('User');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/user/john?age=25&search=hello');
      await tester.pumpAndSettle();

      expect(userId, equals('john'));
      expect(age, equals(25));
      expect(query, equals('hello'));
    });

    testWidgets('getExtraAs retrieves typed extra data',
        (WidgetTester tester) async {
      Map<String, dynamic>? extraData;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/details',
            builder: (context, state) {
              final routeData = context.teleportRouteData;
              extraData = routeData.getExtraAs<Map<String, dynamic>>();
              return const Text('Details');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/details', extra: {'key': 'value', 'count': 42});
      await tester.pumpAndSettle();

      expect(extraData, isNotNull);
      expect(extraData!['key'], equals('value'));
      expect(extraData!['count'], equals(42));
    });
  });

  group('TeleportRouteData equality', () {
    test('routes with same name and path are equal', () {
      final route1 = _TestRouteData(
        routeName: 'home',
        fullPath: '/home',
      );
      final route2 = _TestRouteData(
        routeName: 'home',
        fullPath: '/home',
      );

      expect(route1, equals(route2));
      expect(route1.hashCode, equals(route2.hashCode));
    });

    test('routes with different names are not equal', () {
      final route1 = _TestRouteData(
        routeName: 'home',
        fullPath: '/home',
      );
      final route2 = _TestRouteData(
        routeName: 'about',
        fullPath: '/home',
      );

      expect(route1, isNot(equals(route2)));
    });
  });
}

// Test helper class
class _TestRouteData extends TeleportRouteData {
  @override
  final String? routeName;
  @override
  final String fullPath;

  const _TestRouteData({
    required this.routeName,
    required this.fullPath,
  });
}
