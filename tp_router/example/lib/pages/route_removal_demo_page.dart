import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import '../widgets/location_display.dart';
import '../routes/route.gr.dart';

/// Demonstrates route removal from the navigation stack.
///
/// This example shows how to navigate A -> B -> C and then
/// remove B from the stack, resulting in A -> C.
///
/// Works with different navigator contexts (root, shell branches).
@TpRoute(
  path: '/route-removal-demo',
)
class RouteRemovalDemoPage extends StatelessWidget {
  const RouteRemovalDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Route Removal Demo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.tpRouter.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Route Removal Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This page demonstrates how to remove intermediate routes '
                'from the navigation stack.\n\n'
                'Scenario: Navigate A → B → C, then remove B.\n'
                'Result: Pressing back on C goes directly to A.',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Demo: Navigate to Page A'),
                onPressed: () {
                  // Navigate to Page A (this demo page is already "A")
                  // So we push A-step1 first
                  const RouteStackPageARoute().tp(context);
                },
              ),
              const Divider(height: 32),
              const Text(
                'Available Navigator Keys:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '• Root Navigator\n'
                '• main_branch_0 (Home tab)\n'
                '• main_branch_1 (Settings tab)\n'
                '• dashboard (Dashboard shell)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page A in the route stack demo.
@TpRoute(path: '/route-stack/a')
class RouteStackPageA extends StatelessWidget {
  const RouteStackPageA({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page A'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.looks_one, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Page A',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('This is the starting point.'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Navigate to Page B'),
                onPressed: () {
                  const RouteStackPageBRoute().tp(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page B in the route stack demo (will be removed).
@TpRoute(path: '/route-stack/b')
class RouteStackPageB extends StatelessWidget {
  const RouteStackPageB({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page B (Will Be Removed)'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.looks_two, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Page B',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This page will be removed when you navigate to C.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Navigate to Page C (& Remove B)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // First navigate to C
                  await const RouteStackPageCRoute().tp(context);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Navigate to Page C (Keep B)'),
                onPressed: () {
                  const RouteStackPageCRoute().tp(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page C in the route stack demo.
@TpRoute(path: '/route-stack/c')
class RouteStackPageC extends StatefulWidget {
  const RouteStackPageC({super.key});

  @override
  State<RouteStackPageC> createState() => _RouteStackPageCState();
}

class _RouteStackPageCState extends State<RouteStackPageC> {
  bool _removedB = false;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page C'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.looks_3, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Page C',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_removedB)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.green.withOpacity(0.2),
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                )
              else
                const Text(
                  'Press the button below to remove Page B from the stack.',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              if (!_removedB)
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Page B from Stack'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Remove Page B from the navigation stack
                    // 当前是在主路由上的。
                    final removed = context.tpRouter.removeRoute(
                      RouteStackPageBRoute(),
                    );

                    setState(() {
                      _removedB = true;
                      if (removed) {
                        _message = '✓ Page B removed!\n\n'
                            'Now when you press back, you will go '
                            'directly to Page A.';
                      } else {
                        _message = '✗ Page B not found in stack.\n'
                            '(Maybe already removed?)';
                      }
                    });
                  },
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back (Test the Stack)'),
                onPressed: () => context.tpRouter.pop(),
              ),
              const Divider(height: 32),
              const Text(
                'Advanced: Remove with Navigator Key',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      final removed = TpRouter.instance.removeRoute(
                        RouteStackPageBRoute(),
                      );
                      _showSnackBar(
                        context,
                        removed
                            ? 'Removed from root navigator'
                            : 'Not found in root navigator',
                      );
                    },
                    child: const Text('Remove from Root'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
