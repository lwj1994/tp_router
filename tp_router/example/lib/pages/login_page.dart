import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import '../widgets/location_display.dart';
import 'package:tp_router/tp_router.dart';
import '../routes/route.gr.dart';

@TpRoute(path: '/login')
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
              const HomeRoute().tp(context, replacement: true);
            },
            child: const Text('Login'),
          ),
        ),
      ),
    );
  }
}
