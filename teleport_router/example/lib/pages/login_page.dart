import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import '../widgets/location_display.dart';
import 'package:teleport_router/teleport_router.dart';
import '../routes/route.gr.dart';

@TeleportRoute(
  path: '/login',
  parentNavigatorKey: MainHomeNavKey,
)
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Simulate login and go home
              // In real app, update state here
              const HomeRoute().teleport(replacement: true);
            },
            child: const Text('Login'),
          ),
        ),
      ),
    );
  }
}
