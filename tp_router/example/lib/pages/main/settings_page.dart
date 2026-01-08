import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

/// Settings page - simple route without parameters.
@TpRoute(
  path: '/settings',
  parentNavigatorKey: 'main',
  branchIndex: 1,
)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Current Location'),
            subtitle: Text(context.tpRouter.currentFullPath),
          ),
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
    );
  }
}
