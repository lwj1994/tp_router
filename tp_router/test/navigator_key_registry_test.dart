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
      final key =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('test_nav'));
      expect(key, isNotNull);
    });

    test('getOrCreate returns same key if already exists', () {
      final key1 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('test_nav'));
      final key2 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('test_nav'));
      expect(identical(key1, key2), isTrue);
    });

    test('get returns null for non-existent key', () {
      final key = TpNavigatorKeyRegistry.get(TpNavKey.value('non_existent'));
      expect(key, isNull);
    });

    test('get returns key if exists', () {
      final created =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('my_nav'));
      final fetched = TpNavigatorKeyRegistry.get(TpNavKey.value('my_nav'));
      expect(fetched, isNotNull);
      expect(identical(created, fetched), isTrue);
    });

    test('branch keys work correctly with TpNavKey', () {
      // Create branch keys using TpNavKey with branch parameter
      final b0 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('main', branch: 0));
      final b1 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('main', branch: 1));
      final b2 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('main', branch: 2));

      // Retrieve them again
      final branch0 = TpNavKey.value('main', branch: 0).globalKey;
      final branch1 = TpNavKey.value('main', branch: 1).globalKey;
      final branch2 = TpNavKey.value('main', branch: 2).globalKey;

      expect(identical(branch0, b0), isTrue);
      expect(identical(branch1, b1), isTrue);
      expect(identical(branch2, b2), isTrue);
    });

    test('all returns unmodifiable map of all keys', () {
      TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('nav1'));
      TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('nav2'));

      final all = TpNavigatorKeyRegistry.all;
      expect(all.length, 2);
      expect(all.containsKey(TpNavKey.value('nav1')), isTrue);
      expect(all.containsKey(TpNavKey.value('nav2')), isTrue);
    });

    test('clear removes all keys', () {
      TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('nav1'));
      TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('nav2'));
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
      final removed = TpRouter.instance.removeRoute(const _MockPageBRoute());

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
      final removed = TpRouter.instance.removeRoute(const _MockPageBRoute());

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
      final count = TpRouter.instance.removeWhere(
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

  group('TpNavKey.globalKey', () {
    setUp(() {
      TpNavigatorKeyRegistry.clear();
    });

    test('globalKey returns registered key', () {
      // Pre-register a key
      final dashboardKey =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('dashboard'));

      // Use globalKey directly
      final key = TpNavKey.value('dashboard').globalKey;

      expect(key, isNotNull);
      expect(identical(key, dashboardKey), isTrue);
    });

    test('globalKey with branch returns branch key', () {
      // Pre-register branch keys
      final b0 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('main', branch: 0));
      final b1 =
          TpNavigatorKeyRegistry.getOrCreate(TpNavKey.value('main', branch: 1));

      // Use globalKey directly
      final branch0 = TpNavKey.value('main', branch: 0).globalKey;
      final branch1 = TpNavKey.value('main', branch: 1).globalKey;

      expect(identical(branch0, b0), isTrue);
      expect(identical(branch1, b1), isTrue);
    });

    test('globalKey creates key if not exists', () {
      // globalKey uses getOrCreate, so it always returns a key
      final key = TpNavKey.value('non_existent').globalKey;

      expect(key, isNotNull);
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
