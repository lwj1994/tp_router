import 'package:flutter/material.dart';
import 'package:teleport_router/teleport_router.dart';
import 'routes/route.gr.dart';

void main() {
  // Use generated routes
  final router = TeleportRouter(
    defaultPageType: TeleportPageType.swipeBack,
    routes: teleportRoutes,
    enableLogging: true,
    routerNeglect: true, // Demo new parameter
  );

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final TeleportRouter router;

  const MyApp({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TeleportRouter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router.routerConfig,
    );
  }
}
