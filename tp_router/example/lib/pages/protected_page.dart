import 'package:flutter/material.dart';
import '../widgets/location_display.dart';
import 'package:tp_router/tp_router.dart';
import '../guards/auth_guard.dart';

@TpRoute(path: '/protected', redirect: AuthRedirect)
class ProtectedPage extends StatelessWidget {
  const ProtectedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      child: Scaffold(
        appBar: AppBar(title: const Text('Protected Page')),
        body: const Center(child: Text('You are logged in!')),
      ),
    );
  }
}
