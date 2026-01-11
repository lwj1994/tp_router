import 'package:example/routes/route.gr.dart';
import '../../widgets/location_display.dart';
import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import 'package:teleport_router/teleport_router.dart';

/// Home page - the initial route.
///
/// Usage:
/// ```dart
/// TeleportRouter.instance.teleport(HomeRoute());
/// ```
@TeleportRoute(path: '/', isInitial: true, parentNavigatorKey: MainHomeNavKey)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _result;

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      child: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to TeleportRouter Example!'),
              const SizedBox(height: 20),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.amber.withValues(alpha: 0.2),
                  child: Text('Result from Details: $_result'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  const ProtectedRoute().teleport();
                },
                child: const Text('Go to Protected Page'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  const DetailsRoute(title: 'From Home').teleport();
                },
                child: const Text('Go to Details'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // Type-safe navigation with unified teleport() method
                  UserRoute(id: 123, name: 'John', age: 25).teleport();
                },
                child: const Text('Go to User Page'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // DetailsPage has custom slide transition (500ms enter, 300ms exit)
                  DetailsRoute(title: 'Custom Transition Demo').teleport();
                },
                child: const Text('Go to Details (Custom Transition)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await DetailsRoute(
                    title: 'Waiting for result...',
                  ).teleport<String>();

                  if (mounted) {
                    setState(() {
                      _result = result;
                    });
                  }
                },
                child: const Text('Push Details (Wait Result)'),
              ),
              const Divider(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  // Navigate to route removal demo
                  const RouteRemovalDemoRoute().teleport();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                label: const Text('Route Removal Demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Remote pop to reset Dashboard's navigator to its initial state
                  // This demonstrates controlling a different navigator stack using its NavKey!
                  context.teleportRouter.popToInitial();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dashboard reset to initial route!'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                label: const Text('Reset Dashboard (Pop to Initial)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
