import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tp_router/tp_router.dart';

void main() {
  group('TpRouteData', () {
    test('parses basic parameters correctly', () {
      final data = MockRouteData(
        fullPath: '/user/123',
        pathParams: {'id': '123'},
        queryParams: {'name': 'test', 'active': 'true'},
        extra: {'obj': 'value'},
      );

      expect(data.getString('id'), '123');
      expect(data.getInt('id'), 123);
      expect(data.getString('name'), 'test');
      expect(data.getBool('active'), true);
      expect(data.getExtra<String>('obj'), 'value');
    });

    test('validates required parameters', () {
      final data = MockRouteData(
        fullPath: '/',
        pathParams: {},
        queryParams: {},
        extra: {},
      );
      expect(() => data.getStringRequired('id'), throwsArgumentError);
    });
  });

  group('TpRouter', () {
    // Define reusable routes for testing
    final homeRoute = TpRouteInfo(
      path: '/home',
      isInitial: true,
      builder: (data) => const Text('Home Page'),
    );

    final userRoute = TpRouteInfo(
      path: '/user/:id',
      name: 'user', // Named route
      builder: (data) => Text('User ${data.getInt('id')}'),
    );

    testWidgets('initializes and navigates with tp', (tester) async {
      final router = TpRouter(routes: [homeRoute, userRoute]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);

      router.tp(TpRouteData.fromPath('/user/42'));
      await tester.pumpAndSettle();

      expect(find.text('User 42'), findsOneWidget);
    });

    testWidgets('supports redirect', (tester) async {
      final router = TpRouter(
        routes: [homeRoute, userRoute],
        redirect: (context, state) {
          print('Redirect check: ${state.fullPath}');
          if (state.fullPath == '/home') {
            return const MockRoute('/user/99');
          }
          return null;
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Should be redirected from /home to /user/99
      expect(find.text('User 99'), findsOneWidget);
    });

    testWidgets('TpRouteInfo supports route-level redirect', (tester) async {
      final protectedRoute = TpRouteInfo(
          path: '/protected',
          builder: (data) => const Text('Protected Page'),
          redirect: (context, state) async {
            // Mock auth check
            bool authed = false;
            if (!authed) {
              return const MockRoute('/login');
            }
            return null;
          });

      final loginRoute = TpRouteInfo(
          path: '/login', builder: (data) => const Text('Login Page'));

      final router = TpRouter(routes: [homeRoute, protectedRoute, loginRoute]);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Goto protected
      router.tp(TpRouteData.fromPath('/protected'));
      await tester.pumpAndSettle();

      // Should be redirected to /login
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('supports observers', (tester) async {
      final log = <String>[];
      final observer = TestNavigatorObserver(log);

      final router = TpRouter(
        routes: [homeRoute, userRoute],
        observers: [observer],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Initial route /home
      expect(log, contains(matches(r'didPush .*home')));

      router.tp(TpRouteData.fromPath('/user/100'));
      await tester.pumpAndSettle();

      // Pushed /user/100 (matches /user/:id)
      expect(log, contains(matches(r'didPush .*user')));
    });

    testWidgets('TpRouteData.tp navigates correctly (push, go, replacement)',
        (tester) async {
      final router = TpRouter(routes: [homeRoute, userRoute]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);

      // 1. Test push (default) via TpRouteData.tp
      // MockRoute('/user/1') corresponds to userRoute with id=1
      const MockRoute('/user/1').tp();
      await tester.pumpAndSettle();
      expect(find.text('User 1'), findsOneWidget);

      // Verify stack: Home -> User 1.
      // We can verify this by popping.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);

      // 2. Test replace usage
      // Re-navigate to User 1
      router.tp(TpRouteData.fromPath('/user/1'));
      await tester.pumpAndSettle();
      expect(find.text('User 1'), findsOneWidget);

      // Now replace with User 2
      const MockRoute('/user/2').tp(replacement: true);
      await tester.pumpAndSettle();
      expect(find.text('User 2'), findsOneWidget);

      // Pop should go back to Home (User 1 was replaced)
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);

      // 3. Test go (clearHistory)
      // Push User 1 again
      router.tp(TpRouteData.fromPath('/user/1'));
      await tester.pumpAndSettle();

      // Go to User 3 (clears history)
      const MockRoute('/user/3').tp(clearHistory: true);
      await tester.pumpAndSettle();
      expect(find.text('User 3'), findsOneWidget);
    });

    testWidgets('push returns value from pop', (tester) async {
      final returnRoute = TpRouteInfo(
        path: '/return',
        builder: (data) => const Text('Return Page'),
      );

      final router = TpRouter(routes: [homeRoute, returnRoute]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      final future = router.tp<String>(TpRouteData.fromPath('/return'));
      await tester.pumpAndSettle();
      expect(find.text('Return Page'), findsOneWidget);

      router.pop(result: 'Success!');
      await tester.pumpAndSettle();

      expect(await future, 'Success!');
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('StatefulShellRoute preserves state in IndexedStack',
        (tester) async {
      final tab1 = TpRouteInfo(
        path: '/tab1',
        isInitial: true,
        builder: (data) => const CounterWidget(),
      );
      final tab2 = TpRouteInfo(
        path: '/tab2',
        builder: (data) => const Text('Tab 2 Content'),
      );

      final shellRoute = TpStatefulShellRouteInfo(
        builder: (c, shell) => Column(
          children: [
            Expanded(child: shell),
            Row(
              children: [
                GestureDetector(
                    onTap: () => shell.tp(0), child: const Text('Btn1')),
                GestureDetector(
                    onTap: () => shell.tp(1), child: const Text('Btn2')),
              ],
            )
          ],
        ),
        branches: [
          [tab1],
          [tab2],
        ],
      );

      final router = TpRouter(routes: [shellRoute]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // 1. Initial State: Tab 1, Count 0
      expect(find.text('Count: 0'), findsOneWidget);

      // 2. Increment Count
      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('Count: 1'), findsOneWidget);

      // 3. Switch to Tab 2
      await tester.tap(find.text('Btn2'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 2 Content'), findsOneWidget);
      // Tab 1 should be hidden (IndexedStack) but alive.

      // 4. Switch back to Tab 1
      await tester.tap(find.text('Btn1'));
      await tester.pumpAndSettle();

      // State Key Verification: Count should still be 1
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('supports nested ShellRoutes (Outer -> Inner -> Page)',
        (tester) async {
      // Leaf Page
      final leafRoute = TpRouteInfo(
        path: '/leaf',
        isInitial: true,
        builder: (data) => const Text('Leaf Page'),
      );

      // Inner Shell
      final innerShellRoute = TpShellRouteInfo(
        builder: (context, child) => Column(
          key: const Key('InnerShell'),
          children: [
            const Text('Inner Header'),
            Expanded(child: child),
          ],
        ),
        routes: [leafRoute],
      );

      // Outer Shell
      final outerShellRoute = TpShellRouteInfo(
        builder: (context, child) => Column(
          key: const Key('OuterShell'),
          children: [
            const Text('Outer Header'),
            Expanded(child: child),
          ],
        ),
        routes: [innerShellRoute],
      );

      final router = TpRouter(routes: [outerShellRoute]);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      debugDumpApp();

      // Navigate to leaf
      // Initial route matching logic might default to /leaf if it's the only one available via traversal
      // or we might need to explicit nav. behavior depends on _findInitialPath logic which drills down.
      // Let's verify if auto-initial works:
      // Outer -> Inner -> Leaf (path: /leaf)
      // _findInitialPath should return /leaf.

      expect(find.text('Leaf Page'), findsOneWidget);
      expect(find.text('Inner Header'), findsOneWidget);
      expect(find.text('Outer Header'), findsOneWidget);

      // Verify Hierarchy
      expect(
        find.descendant(
          of: find.byKey(const Key('OuterShell')),
          matching: find.byKey(const Key('InnerShell')),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('InnerShell')),
          matching: find.text('Leaf Page'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('supports custom pageBuilder via TpPageFactory',
        (tester) async {
      SpyPageFactory.callCount = 0;
      SpyPageFactory.lastKey = null;

      final customRoute = TpRouteInfo(
        path: '/custom',
        builder: (data) => const Text('Custom Page'),
        pageBuilder: const SpyPageFactory(),
      );

      final router = TpRouter(routes: [customRoute]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router.routerConfig,
      ));
      await tester.pumpAndSettle();

      // Navigate to custom route
      router.tp(TpRouteData.fromPath('/custom'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Page'), findsOneWidget);
      expect(SpyPageFactory.callCount, greaterThanOrEqualTo(1));
      expect(SpyPageFactory.lastKey, isNotNull);
    });
  });
}

// Helper Classes

class TestNavigatorObserver extends NavigatorObserver {
  final List<String> log;
  TestNavigatorObserver(this.log);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      log.add('didPush ${route.settings.name}');
    } else {
      // Fallback for unnamed routes (often matched path logic in GoRouter)
      log.add('didPush ${route.settings.toString()}');
    }
  }
}

class MockRoute extends TpRouteData {
  @override
  final String fullPath;
  @override
  final Map<String, dynamic> extra;

  String get routeName => fullPath;

  const MockRoute(this.fullPath, {this.extra = const {}});
}

/// Mock route data for testing parameter parsing.
class MockRouteData extends TpRouteData {
  @override
  final String fullPath;
  @override
  final Map<String, String> pathParams;
  @override
  final Map<String, String> queryParams;
  @override
  final Map<String, dynamic> extra;

  String get routeName => fullPath;

  const MockRouteData({
    required this.fullPath,
    required this.pathParams,
    required this.queryParams,
    required this.extra,
  });
}

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class SpyPageFactory extends TpPageFactory {
  static int callCount = 0;
  static LocalKey? lastKey;

  const SpyPageFactory();

  @override
  Page<dynamic> buildPage(
      BuildContext context, TpRouteData data, Widget child) {
    callCount++;
    lastKey = data.pageKey;
    return MaterialPage(
      child: child,
      key: data.pageKey,
      name: 'SpyPage',
      arguments: data,
    );
  }
}
