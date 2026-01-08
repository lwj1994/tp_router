import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tp_router/tp_router.dart';

void main() {
  group('TpNavigatorKeyRegistry', () {
    setUp(() {
      // Clear registry before each test
      TpNavigatorKeyRegistry.clear();
    });

    test('getOrCreate creates new key if not exists', () {
      final key = TpNavigatorKeyRegistry.getOrCreate('test_nav');
      expect(key, isNotNull);
    });

    test('getOrCreate returns same key if already exists', () {
      final key1 = TpNavigatorKeyRegistry.getOrCreate('test_nav');
      final key2 = TpNavigatorKeyRegistry.getOrCreate('test_nav');
      expect(identical(key1, key2), isTrue);
    });

    test('get returns null for non-existent key', () {
      final key = TpNavigatorKeyRegistry.get('non_existent');
      expect(key, isNull);
    });

    test('get returns key if exists', () {
      final created = TpNavigatorKeyRegistry.getOrCreate('my_nav');
      final fetched = TpNavigatorKeyRegistry.get('my_nav');
      expect(fetched, isNotNull);
      expect(identical(created, fetched), isTrue);
    });

    test('getBranch returns correct branch key', () {
      // Create branch keys
      final b0 = TpNavigatorKeyRegistry.getOrCreate('main_branch_0');
      final b1 = TpNavigatorKeyRegistry.getOrCreate('main_branch_1');
      final b2 = TpNavigatorKeyRegistry.getOrCreate('main_branch_2');

      final branch0 = TpNavigatorKeyRegistry.getBranch('main', 0);
      final branch1 = TpNavigatorKeyRegistry.getBranch('main', 1);
      final branch2 = TpNavigatorKeyRegistry.getBranch('main', 2);

      expect(branch0, isNotNull);
      expect(branch1, isNotNull);
      expect(branch2, isNotNull);
      expect(identical(branch0, b0), isTrue);
      expect(identical(branch1, b1), isTrue);
      expect(identical(branch2, b2), isTrue);
    });

    test('getBranch returns null for non-existent branch', () {
      final branch = TpNavigatorKeyRegistry.getBranch('main', 99);
      expect(branch, isNull);
    });

    test('all returns unmodifiable map of all keys', () {
      TpNavigatorKeyRegistry.getOrCreate('nav1');
      TpNavigatorKeyRegistry.getOrCreate('nav2');

      final all = TpNavigatorKeyRegistry.all;
      expect(all.length, 2);
      expect(all.containsKey('nav1'), isTrue);
      expect(all.containsKey('nav2'), isTrue);

      // Should be unmodifiable
      expect(
        () => all['nav3'] = GlobalKey<NavigatorState>(),
        throwsA(anything),
      );
    });

    test('clear removes all keys', () {
      TpNavigatorKeyRegistry.getOrCreate('nav1');
      TpNavigatorKeyRegistry.getOrCreate('nav2');
      expect(TpNavigatorKeyRegistry.all.length, 2);

      TpNavigatorKeyRegistry.clear();
      expect(TpNavigatorKeyRegistry.all.length, 0);
    });
  });

  // Note: removeRoute tests require proper TpRouteObserver integration
  // These tests are skipped because getObserver() cannot find the observer
  // in a simple widget test context. Consider integration tests instead.
  // These tests fail because Flutter Navigator does not allow imperative removal
  // of Page-based routes (which GoRouter uses).
  group('TpRouter removeRoute', () {
    late TpRouteInfo homeRoute;
    late TpRouteInfo pageARoute;
    late TpRouteInfo pageBRoute;
    late TpRouteInfo pageCRoute;

    setUp(() {
      TpNavigatorKeyRegistry.clear();

      homeRoute = TpRouteInfo(
        path: '/home',
        name: 'tp_router_HomeRoute',
        isInitial: true,
        builder: (data) => const Text('Home Page'),
      );
      pageARoute = TpRouteInfo(
        path: '/page-a',
        name: 'tp_router_PageARoute',
        builder: (data) => const Text('Page A'),
      );
      pageBRoute = TpRouteInfo(
        path: '/page-b',
        name: 'tp_router_PageBRoute',
        builder: (data) => const Text('Page B'),
      );
      pageCRoute = TpRouteInfo(
        path: '/page-c',
        name: 'tp_router_PageCRoute',
        builder: (data) => const Text('Page C'),
      );
    });

    testWidgets('removeRoute removes intermediate route from stack',
        (tester) async {
      final router = TpRouter(
        routes: [homeRoute, pageARoute, pageBRoute, pageCRoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Start at Home
      expect(find.text('Home Page'), findsOneWidget);

      // Navigate: Home -> A -> B -> C
      router.tp(TpRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();
      expect(find.text('Page A'), findsOneWidget);

      router.tp(TpRouteData.fromPath('/page-b'));
      await tester.pumpAndSettle();
      expect(find.text('Page B'), findsOneWidget);

      router.tp(TpRouteData.fromPath('/page-c'));
      await tester.pumpAndSettle();
      expect(find.text('Page C'), findsOneWidget);

      // Now remove B from the stack
      final context = tester.element(find.text('Page C'));
      final removed = context.tpRouter.removeRoute(const _MockPageBRoute());

      expect(removed, isTrue);

      // Pop from C should go directly to A (B was removed)
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Page A'), findsOneWidget);
    });

    testWidgets('removeRoute returns false if route not found', (tester) async {
      final router = TpRouter(
        routes: [homeRoute, pageARoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Navigate: Home -> A
      router.tp(TpRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();

      // Try to remove B which is not in the stack
      final context = tester.element(find.text('Page A'));
      final removed = context.tpRouter.removeRoute(const _MockPageBRoute());

      expect(removed, isFalse);
    });

    testWidgets('removeWhere removes multiple matching routes', (tester) async {
      final router = TpRouter(
        routes: [homeRoute, pageARoute, pageBRoute, pageCRoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Navigate: Home -> A -> B -> C
      router.tp(TpRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();
      router.tp(TpRouteData.fromPath('/page-b'));
      await tester.pumpAndSettle();
      router.tp(TpRouteData.fromPath('/page-c'));
      await tester.pumpAndSettle();

      // Remove all routes containing 'page-a' or 'page-b' in their path
      final context = tester.element(find.text('Page C'));
      final count = context.tpRouter.removeWhere(
        (data) =>
            data.fullPath.contains('page-a') ||
            data.fullPath.contains('page-b'),
      );

      // Should have removed A and B
      expect(count, 2);

      // Pop from C should go directly to Home
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });
  });

  group('TpRouterContext getNavigatorKey', () {
    setUp(() {
      TpNavigatorKeyRegistry.clear();
    });

    testWidgets('getNavigatorKey returns registered key', (tester) async {
      // Pre-register a key
      final dashboardKey = TpNavigatorKeyRegistry.getOrCreate('dashboard');

      final homeRoute = TpRouteInfo(
        path: '/',
        isInitial: true,
        builder: (data) => const Text('Home'),
      );

      final router = TpRouter(routes: [homeRoute]);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Home'));
      final key = context.tpRouter.getNavigatorKey('dashboard');

      expect(key, isNotNull);
      expect(identical(key, dashboardKey), isTrue);
    });

    testWidgets('getNavigatorKey with branch returns branch key',
        (tester) async {
      // Pre-register branch keys (simulating generated code)
      final b0 = TpNavigatorKeyRegistry.getOrCreate('main_branch_0');
      final b1 = TpNavigatorKeyRegistry.getOrCreate('main_branch_1');

      final homeRoute = TpRouteInfo(
        path: '/',
        isInitial: true,
        builder: (data) => const Text('Home'),
      );

      final router = TpRouter(routes: [homeRoute]);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Home'));

      final branch0 = context.tpRouter.getNavigatorKey('main', branch: 0);
      final branch1 = context.tpRouter.getNavigatorKey('main', branch: 1);

      expect(branch0, isNotNull);
      expect(identical(branch0, b0), isTrue);
      expect(branch1, isNotNull);
      expect(identical(branch1, b1), isTrue);
    });

    testWidgets('getNavigatorKey returns null for unregistered key',
        (tester) async {
      final homeRoute = TpRouteInfo(
        path: '/',
        isInitial: true,
        builder: (data) => const Text('Home'),
      );

      final router = TpRouter(routes: [homeRoute]);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Home'));
      final key = context.tpRouter.getNavigatorKey('non_existent');

      expect(key, isNull);
    });
  });
}

/// Mock route for testing removeRoute.
class _MockPageBRoute extends TpRouteData {
  const _MockPageBRoute();

  @override
  String get routeName => 'tp_router_PageBRoute';

  @override
  String get fullPath => '/page-b';

  @override
  Map<String, dynamic> get extra => const {};
}
