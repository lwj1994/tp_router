import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpShellRoute(
  navigatorKey: 'dashboard',
  parentNavigatorKey: 'main',
  branchIndex: 2,
  opaque: true,
  observers: [DashboardObserver],
)
class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: child,
    );
  }
}

class DashboardObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('DashboardObserver: didPush ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('DashboardObserver: didReplace ${newRoute?.settings.name}');
  }
}
