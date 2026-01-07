import 'package:example/routes/route.gr.dart';
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpRoute(path: '/dashboard/analytics', parentNavigatorKey: 'dashboard')
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Analytics Overview', style: TextStyle(fontSize: 24)),
          Text('Charts and graphs go here'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.tpRouter.pop(),
            child: Text('Back to Overview'),
          ),
          ElevatedButton(
            onPressed: () => DashboardOverviewRoute().tp(context),
            child: Text('DashboardOverviewRoute'),
          ),
        ],
      ),
    );
  }
}
