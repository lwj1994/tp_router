import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tp_router/tp_router.dart';

// 1. Define a NavKey
class TestNavKey extends TpNavKey {
  const TestNavKey() : super('test_key');
}

// Helper for testing
class SimpleRoute extends TpRouteData {
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
  group('TpNavKey API', () {
    late TpRouter router;

    setUp(() {
      // Reset singleton if possible, or just create new one (which overwrites instance)
    });

    testWidgets('calls TpRouter methods with correct navigatorKey',
        (tester) async {
      final homeRoute = TpRouteInfo(
        path: '/home',
        name: 'home',
        isInitial: true,
        builder: (data) => const Text('Home'),
      );
      final page2 = TpRouteInfo(
        path: '/page2',
        name: 'page2',
        builder: (data) => const Text('Page 2'),
      );

      // Initialize Router with the test key
      router = TpRouter(
        routes: [homeRoute, page2],
        navigatorKey: const TestNavKey().globalKey,
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // 1. Test NavKey().tp()
      // Do not await tp() as it completes when route is popped
      const TestNavKey().tp(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      // 2. Test NavKey().pop()
      const TestNavKey().pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // 3. Test NavKey().canPop (false at root)
      expect(const TestNavKey().canPop, isFalse);

      // Push again to test canPop true
      const TestNavKey().tp(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();
      expect(const TestNavKey().canPop, isTrue);

      // 4. Test currentFullPath
      print('Current path: ${const TestNavKey().location.fullPath}');
      // expect(const TestNavKey().currentFullPath, '/page2');

      // Test popTo
      const TestNavKey()
          .tp(SimpleRoute('/page2', name: 'page2', extra: {'id': 1}));
      await tester.pumpAndSettle();
      // Path should include query params if implemented, but here logic depends on how GoRouter constructs URI from implicit extra?
      // Actually GoRouter doesn't auto-add extra to URI query params.
      // So path remains /page2. Extra is invisible in URI string unless mapped.

      const TestNavKey()
          .tp(SimpleRoute('/page2', name: 'page2', extra: {'id': 2}));
      await tester.pumpAndSettle();

      // Should pop back to home (original route) if we popTo HomeRoute
      const TestNavKey().popTo(SimpleRoute('/home', name: 'home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(const TestNavKey().location.fullPath, '/home');

      // Test popToInitial
      const TestNavKey().tp(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();
      const TestNavKey().tp(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle(); // Stack: Home -> Page2 -> Page2

      const TestNavKey().popToInitial();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(const TestNavKey().location.fullPath, '/home');

      // 5. Test popUntil
      const TestNavKey().tp(SimpleRoute('/page2', name: 'page2'));
      await tester.pumpAndSettle();

      // Pop until home
      const TestNavKey().popUntil((route, data) {
        return data?.routeName == 'home';
      });
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
