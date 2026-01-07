import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import 'routes/route.gr.dart';

void main() {
  // Use generated routes
  final router = TpRouter(
    routes: tpRoutes,
    routerNeglect: true, // Demo new parameter
  );

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final TpRouter router;

  const MyApp({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TpRouter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router.routerConfig,
    );
  }
}
