import 'package:flutter/material.dart';
import 'package:teleport_router/teleport_router.dart';
import 'package:example/routes/nav_keys.dart';

@TeleportShellRoute(navigatorKey: MainNavKey, isIndexedStack: true, observers: [
  AObserver
], branchKeys: [
  MainHomeNavKey,
  MainSettingNavKey,
  MainDashBoradNavKey,
])
class MainShellPage extends StatelessWidget {
  final TeleportStatefulNavigationShell navigationShell;

  const MainShellPage({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeleportRouter Shell Example'),
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
    navigationShell.teleport(
      index,
    );
  }
}

class AObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    LogUtil.info("AObserver: ${route.settings.name ?? ""}");
  }
}
