import 'package:flutter/material.dart';
import '../../widgets/location_display.dart';
import 'package:tp_router/tp_router.dart';
import 'package:example/routes/nav_keys.dart';

/// Settings page - simple route without parameters.
@TpRoute(
  path: '/settings',
  parentNavigatorKey: MainNavKey,
  branchIndex: 1,
)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Theme'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Notifications'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    ));
  }
}
