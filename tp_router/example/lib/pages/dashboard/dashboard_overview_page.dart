import 'package:example/routes/route.gr.dart';
import '../../widgets/location_display.dart';
import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpRoute(
  path: '/dashboard/overview',
  parentNavigatorKey: DashboardNavKey,
  isInitial: true,
)
class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: DashboardNavKey(),
      bottom: 100,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Dashboard Overview', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.tpRouter.pop();
                },
                child: const Text('pop'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Navigate to reports within the same shell
                  const ReportsRoute().tp(context);
                },
                child: const Text('Go to Reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
