import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleport_router/src/navigator_key_registry.dart';
import 'package:teleport_router/teleport_router.dart';

void main() {
  group('TeleportNavigatorKeyRegistry', () {
    setUp(() {
      // Clear registry before each test
      TeleportNavigatorKeyRegistry.clear();
    });

    test('getOrCreate creates new key if not exists', () {
      final key = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('test_nav'));
      expect(key, isNotNull);
    });

    test('getOrCreate returns same key if already exists', () {
      final key1 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('test_nav'));
      final key2 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('test_nav'));
      expect(identical(key1, key2), isTrue);
    });

    test('get returns null for non-existent key', () {
      final key = TeleportNavigatorKeyRegistry.get(
          TeleportNavKey.value('non_existent'));
      expect(key, isNull);
    });

    test('get returns key if exists', () {
      final created = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('my_nav'));
      final fetched =
          TeleportNavigatorKeyRegistry.get(TeleportNavKey.value('my_nav'));
      expect(fetched, isNotNull);
      expect(identical(created, fetched), isTrue);
    });

    test('branch keys work correctly with TeleportNavKey', () {
      // Create branch keys using TeleportNavKey with branch parameter
      final b0 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('main', branch: 0));
      final b1 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('main', branch: 1));
      final b2 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('main', branch: 2));

      // Retrieve them again
      final branch0 = TeleportNavKey.value('main', branch: 0).globalKey;
      final branch1 = TeleportNavKey.value('main', branch: 1).globalKey;
      final branch2 = TeleportNavKey.value('main', branch: 2).globalKey;

      expect(identical(branch0, b0), isTrue);
      expect(identical(branch1, b1), isTrue);
      expect(identical(branch2, b2), isTrue);
    });

    test('all returns unmodifiable map of all keys', () {
      TeleportNavigatorKeyRegistry.getOrCreate(TeleportNavKey.value('nav1'));
      TeleportNavigatorKeyRegistry.getOrCreate(TeleportNavKey.value('nav2'));

      final all = TeleportNavigatorKeyRegistry.all;
      expect(all.length, 2);
      expect(all.containsKey(TeleportNavKey.value('nav1')), isTrue);
      expect(all.containsKey(TeleportNavKey.value('nav2')), isTrue);
    });

    test('clear removes all keys', () {
      TeleportNavigatorKeyRegistry.getOrCreate(TeleportNavKey.value('nav1'));
      TeleportNavigatorKeyRegistry.getOrCreate(TeleportNavKey.value('nav2'));
      expect(TeleportNavigatorKeyRegistry.all.length, 2);

      TeleportNavigatorKeyRegistry.clear();
      expect(TeleportNavigatorKeyRegistry.all.length, 0);
    });
  });

  // Note: removeRoute tests require proper TeleportRouteObserver integration
  // These tests are skipped because getObserver() cannot find the observer
  // in a simple widget test context. Consider integration tests instead.
  // These tests fail because Flutter Navigator does not allow imperative removal
  // of Page-based routes (which GoRouter uses).
  group('TeleportRouter removeRoute', () {
    late TeleportRouteInfo homeRoute;
    late TeleportRouteInfo pageARoute;
    late TeleportRouteInfo pageBRoute;
    late TeleportRouteInfo pageCRoute;

    setUp(() {
      TeleportNavigatorKeyRegistry.clear();

      homeRoute = TeleportRouteInfo(
        path: '/home',
        name: 'teleport_router_HomeRoute',
        isInitial: true,
        builder: (data) => const Text('Home Page'),
      );
      pageARoute = TeleportRouteInfo(
        path: '/page-a',
        name: 'teleport_router_PageARoute',
        builder: (data) => const Text('Page A'),
      );
      pageBRoute = TeleportRouteInfo(
        path: '/page-b',
        name: 'teleport_router_PageBRoute',
        builder: (data) => const Text('Page B'),
      );
      pageCRoute = TeleportRouteInfo(
        path: '/page-c',
        name: 'teleport_router_PageCRoute',
        builder: (data) => const Text('Page C'),
      );
    });

    testWidgets('removeRoute removes intermediate route from stack',
        (tester) async {
      final router = TeleportRouter(
        routes: [homeRoute, pageARoute, pageBRoute, pageCRoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Start at Home
      expect(find.text('Home Page'), findsOneWidget);

      // Navigate: Home -> A -> B -> C
      router.teleport(TeleportRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();
      expect(find.text('Page A'), findsOneWidget);

      router.teleport(TeleportRouteData.fromPath('/page-b'));
      await tester.pumpAndSettle();
      expect(find.text('Page B'), findsOneWidget);

      router.teleport(TeleportRouteData.fromPath('/page-c'));
      await tester.pumpAndSettle();
      expect(find.text('Page C'), findsOneWidget);

      // Now remove B from the stack
      final removed =
          TeleportRouter.instance.removeRoute(const _MockPageBRoute());

      expect(removed, isTrue);

      // Pop from C should go directly to A (B was removed)
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Page A'), findsOneWidget);
    });

    testWidgets('removeRoute returns false if route not found', (tester) async {
      final router = TeleportRouter(
        routes: [homeRoute, pageARoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Navigate: Home -> A
      router.teleport(TeleportRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();

      // Try to remove B which is not in the stack
      final removed =
          TeleportRouter.instance.removeRoute(const _MockPageBRoute());

      expect(removed, isFalse);
    });

    testWidgets('removeWhere removes multiple matching routes', (tester) async {
      final router = TeleportRouter(
        routes: [homeRoute, pageARoute, pageBRoute, pageCRoute],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Navigate: Home -> A -> B -> C
      router.teleport(TeleportRouteData.fromPath('/page-a'));
      await tester.pumpAndSettle();
      router.teleport(TeleportRouteData.fromPath('/page-b'));
      await tester.pumpAndSettle();
      router.teleport(TeleportRouteData.fromPath('/page-c'));
      await tester.pumpAndSettle();

      // Remove all routes containing 'page-a' or 'page-b' in their path
      final count = TeleportRouter.instance.removeWhere(
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

  group('TeleportNavKey.globalKey', () {
    setUp(() {
      TeleportNavigatorKeyRegistry.clear();
    });

    test('globalKey returns registered key', () {
      // Pre-register a key
      final dashboardKey = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('dashboard'));

      // Use globalKey directly
      final key = TeleportNavKey.value('dashboard').globalKey;

      expect(key, isNotNull);
      expect(identical(key, dashboardKey), isTrue);
    });

    test('globalKey with branch returns branch key', () {
      // Pre-register branch keys
      final b0 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('main', branch: 0));
      final b1 = TeleportNavigatorKeyRegistry.getOrCreate(
          TeleportNavKey.value('main', branch: 1));

      // Use globalKey directly
      final branch0 = TeleportNavKey.value('main', branch: 0).globalKey;
      final branch1 = TeleportNavKey.value('main', branch: 1).globalKey;

      expect(identical(branch0, b0), isTrue);
      expect(identical(branch1, b1), isTrue);
    });

    test('globalKey creates key if not exists', () {
      // globalKey uses getOrCreate, so it always returns a key
      final key = TeleportNavKey.value('non_existent').globalKey;

      expect(key, isNotNull);
    });
  });
}

/// Mock route for testing removeRoute.
class _MockPageBRoute extends TeleportRouteData {
  const _MockPageBRoute();

  @override
  String get routeName => 'teleport_router_PageBRoute';

  @override
  String get fullPath => '/page-b';

  @override
  Map<String, dynamic> get extra => const {};
}
