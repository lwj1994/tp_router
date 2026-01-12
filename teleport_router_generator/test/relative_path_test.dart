import 'package:test/test.dart';
import 'package:teleport_router_generator/src/models/route_data.dart';
import 'package:teleport_router_generator/src/writers/route_writer.dart';

void main() {
  group('Relative Path Resolution', () {
    late RouteWriter writer;

    setUp(() {
      writer = RouteWriter();
    });

    test('resolves relative path with basePath', () {
      final shell = ShellRouteData(
        className: 'DashboardShell',
        routeClassName: 'DashboardShellRoute',
        navigatorKey: 'DashboardNavKey',
        basePath: '/dashboard',
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'OverviewPage',
        routeClassName: 'OverviewRoute',
        path: 'overview',
        originalPath: 'overview',
        parentNavigatorKey: 'DashboardNavKey',
        isInitial: false,
        params: [],
      );

      final allRoutes = [shell, route];
      final output = writer.generateFile(allRoutes, {});

      // Check that the generated path is the resolved absolute path
      expect(output, contains("path: '/dashboard/overview'"));
      // Check that pathPattern is the original relative path
      expect(output, contains("String get pathPattern => 'overview'"));
    });

    test('handles basePath with trailing slash', () {
      final shell = ShellRouteData(
        className: 'DashboardShell',
        routeClassName: 'DashboardShellRoute',
        navigatorKey: 'DashboardNavKey',
        basePath: '/dashboard/',
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'AnalyticsPage',
        routeClassName: 'AnalyticsRoute',
        path: 'analytics',
        originalPath: 'analytics',
        parentNavigatorKey: 'DashboardNavKey',
        isInitial: false,
        params: [],
      );

      final allRoutes = [shell, route];
      final output = writer.generateFile(allRoutes, {});

      // Should normalize to /dashboard/analytics (no double slash)
      expect(output, contains("path: '/dashboard/analytics'"));
    });

    test('keeps absolute paths unchanged', () {
      final shell = ShellRouteData(
        className: 'DashboardShell',
        routeClassName: 'DashboardShellRoute',
        navigatorKey: 'DashboardNavKey',
        basePath: '/dashboard',
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'SettingsPage',
        routeClassName: 'SettingsRoute',
        path: '/settings',
        originalPath: '/settings',
        parentNavigatorKey: 'DashboardNavKey',
        isInitial: false,
        params: [],
      );

      final allRoutes = [shell, route];
      final output = writer.generateFile(allRoutes, {});

      // Absolute path should remain unchanged
      expect(output, contains("path: '/settings'"));
      expect(output, contains("String get pathPattern => '/settings'"));
    });

    test('handles route without shell basePath', () {
      final route = RouteData(
        className: 'HomePage',
        routeClassName: 'HomeRoute',
        path: '/home',
        originalPath: '/home',
        isInitial: true,
        params: [],
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      expect(output, contains("path: '/home'"));
      expect(output, contains("String get pathPattern => '/home'"));
    });

    test('defaults basePath to "/" when shell has no basePath specified', () {
      final shell = ShellRouteData(
        className: 'MainShell',
        routeClassName: 'MainShellRoute',
        navigatorKey: 'MainNavKey',
        basePath: null, // No basePath specified
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'HomePage',
        routeClassName: 'HomeRoute',
        path: 'home',
        originalPath: 'home',
        parentNavigatorKey: 'MainNavKey',
        isInitial: false,
        params: [],
      );

      final allRoutes = [shell, route];
      final output = writer.generateFile(allRoutes, {});

      // Should resolve to /home (with implicit basePath: '/')
      expect(output, contains("path: '/home'"));
      expect(output, contains("String get pathPattern => 'home'"));
    });

    test('handles nested shells with basePaths', () {
      final parentShell = ShellRouteData(
        className: 'MainShell',
        routeClassName: 'MainShellRoute',
        navigatorKey: 'MainNavKey',
        basePath: '/main',
        isIndexedStack: false,
      );

      final childShell = ShellRouteData(
        className: 'DashboardShell',
        routeClassName: 'DashboardShellRoute',
        navigatorKey: 'DashboardNavKey',
        parentNavigatorKey: 'MainNavKey',
        basePath: '/main/dashboard',
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'OverviewPage',
        routeClassName: 'OverviewRoute',
        path: 'overview',
        originalPath: 'overview',
        parentNavigatorKey: 'DashboardNavKey',
        isInitial: false,
        params: [],
      );

      final allRoutes = [parentShell, childShell, route];
      final output = writer.generateFile(allRoutes, {});

      // Should resolve to full path
      expect(output, contains("path: '/main/dashboard/overview'"));
      expect(output, contains("String get pathPattern => 'overview'"));
    });
  });

  group('Path Pattern Generation', () {
    test('generates pathPattern for route with path parameters', () {
      final route = RouteData(
        className: 'UserProfilePage',
        routeClassName: 'UserProfileRoute',
        path: '/user/:id/profile',
        originalPath: '/user/:id/profile',
        isInitial: false,
        params: [
          ParamData(
            name: 'id',
            urlName: 'id',
            type: 'int',
            baseType: 'int',
            isRequired: true,
            isNullable: false,
            isNamed: true,
            source: 'path',
          ),
        ],
      );

      final allRoutes = [route];
      final writer = RouteWriter();
      final output = writer.generateFile(allRoutes, {});

      // Original pattern should be preserved in pathPattern
      expect(output, contains("String get pathPattern => '/user/:id/profile'"));
      // fullPath should have parameter substitution logic
      expect(output, contains("p = p.replaceAll(':id', id.toString())"));
    });

    test('preserves original relative path in pathPattern', () {
      final shell = ShellRouteData(
        className: 'DashboardShell',
        routeClassName: 'DashboardShellRoute',
        navigatorKey: 'DashboardNavKey',
        basePath: '/dashboard',
        isIndexedStack: false,
      );

      final route = RouteData(
        className: 'ReportsPage',
        routeClassName: 'ReportsRoute',
        path: 'reports/:reportId',
        originalPath: 'reports/:reportId',
        parentNavigatorKey: 'DashboardNavKey',
        isInitial: false,
        params: [
          ParamData(
            name: 'reportId',
            urlName: 'reportId',
            type: 'String',
            baseType: 'String',
            isRequired: true,
            isNullable: false,
            isNamed: true,
            source: 'path',
          ),
        ],
      );

      final allRoutes = [shell, route];
      final writer = RouteWriter();
      final output = writer.generateFile(allRoutes, {});

      // Resolved path in routeInfo
      expect(output, contains("path: '/dashboard/reports/:reportId'"));
      // Original relative pattern in pathPattern getter
      expect(output, contains("String get pathPattern => 'reports/:reportId'"));
    });
  });
}
