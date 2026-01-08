import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import 'package:example/routes/nav_keys.dart';

@TpShellRoute(
    navigatorKey: MainNavKey, isIndexedStack: true, observers: [AObserver])
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;

  const MainShellPage({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TpRouter Shell Example'),
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      // A common pattern when switching branches is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class AObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    print("AObserver${route.settings.name ?? ""}");
  }
}
