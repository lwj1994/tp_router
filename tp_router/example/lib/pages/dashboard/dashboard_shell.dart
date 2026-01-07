import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import 'analytics_page.dart';
import 'reports_page.dart';
import 'dashboard_overview_page.dart';

@TpShellRoute(
  children: [DashboardOverviewPage, AnalyticsPage, ReportsPage],
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
