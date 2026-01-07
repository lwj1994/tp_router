import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import '../tp_router.gr.dart';

@TpRoute(path: '/login')
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
