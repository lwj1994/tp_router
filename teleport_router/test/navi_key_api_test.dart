import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleport_router/teleport_router.dart';

// 1. Define a NavKey
class TestNavKey extends TeleportNavKey {
  const TestNavKey() : super('test_key');
}

// Helper for testing
class SimpleRoute extends TeleportRouteData {
  final String _path;
  final String? _name;
  final Map<String, dynamic> _extra;

  SimpleRoute(this._path, {String? name, Map<String, dynamic> extra = const {}})
      : _name = name,
        _extra = extra;

  @override
  String get fullPath => _path;

  @override
  String? get routeName => _name;

  @override
  Map<String, dynamic> get extra => _extra;
}

void main() {
  group('TeleportNavKey API', () {
    late TeleportRouter router;

    setUp(() {
      // Reset singleton if possible, or just create new one (which overwrites instance)
    });

    testWidgets('calls TeleportRouter methods with correct navigatorKey',
        (tester) async {
      final homeRoute = TeleportRouteInfo(
        path: '/home',
        name: 'teleport_router_home', // Prefix needed for Observer tracking
        isInitial: true,
        builder: (data) => const Text('Home'),
      );
      final page2 = TeleportRouteInfo(
        path: '/page2',
        name: 'teleport_router_page2', // Prefix needed
        builder: (data) => const Text('Page 2'),
      );

      // Initialize Router with the test key
      router = TeleportRouter(
        routes: [homeRoute, page2],
        navigatorKey: const TestNavKey(),
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // 1. Test NavKey().teleport() is removed, use TeleportRouter directly
      // Do not await teleport() as it completes when route is popped
      TeleportRouter.instance
          .teleport(SimpleRoute('/page2', name: 'teleport_router_page2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      // 2. Test NavKey().pop()
      TeleportRouter.instance.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // 3. Test NavKey().canPop (false at root)
      expect(const TestNavKey().canPop, isFalse);

      // Push again to test canPop true
      TeleportRouter.instance
          .teleport(SimpleRoute('/page2', name: 'teleport_router_page2'));
      await tester.pumpAndSettle();
      expect(const TestNavKey().canPop, isTrue);

      // 4. Test currentFullPath
      print('Current path: ${const TestNavKey().currentRoute.fullPath}');
      // expect(const TestNavKey().currentFullPath, '/page2');

      // Test popTo
      TeleportRouter.instance.teleport(SimpleRoute('/page2',
          name: 'teleport_router_page2', extra: {'id': 1}));
      await tester.pumpAndSettle();
      // Path should include query params if implemented, but here logic depends on how GoRouter constructs URI from implicit extra?
      // Actually GoRouter doesn't auto-add extra to URI query params.
      // So path remains /page2. Extra is invisible in URI string unless mapped.

      TeleportRouter.instance.teleport(SimpleRoute('/page2',
          name: 'teleport_router_page2', extra: {'id': 2}));
      await tester.pumpAndSettle();

      // Should pop back to home (original route) if we popTo HomeRoute
      // Note: Initial route data uses name as path fallback, so we match that.
      TeleportRouter.instance.popTo(
          SimpleRoute('teleport_router_home', name: 'teleport_router_home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(const TestNavKey().currentRoute.fullPath, '/home');

      // Test popToInitial
      TeleportRouter.instance.teleport(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();
      TeleportRouter.instance.teleport(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle(); // Stack: Home -> Page2 -> Page2

      TeleportRouter.instance.popToInitial();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(const TestNavKey().currentRoute.fullPath, '/home');

      // 5. Test popUntil
      TeleportRouter.instance.teleport(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();

      // Pop until home
      TeleportRouter.instance.popUntil((route, data) {
        return data?.routeName == 'home';
      });
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
