import 'package:example/routes/route.gr.dart';
import '../../widgets/location_display.dart';
import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import 'package:teleport_router/teleport_router.dart';

@TeleportRoute(
  path: '/dashboard/analytics',
  parentNavigatorKey: MainDashBoradNavKey,
)
class AnalyticsPage extends StatelessWidget {
  final String? title;

  const AnalyticsPage({this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainDashBoradNavKey(),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(title ?? 'Analytics Overview',
                  style: TextStyle(fontSize: 24)),
              Text('Charts and graphs go here'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => TeleportRouter.instance.pop(),
                child: Text('Back to Overview'),
              ),
              ElevatedButton(
                onPressed: () => DashboardOverviewRoute().teleport(),
                child: Text('DashboardOverviewRoute'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
