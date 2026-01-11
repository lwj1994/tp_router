import 'package:flutter/material.dart';
import 'package:teleport_router_annotation/teleport_router_annotation.dart';

// This is a minimal example showing annotation usage.
// Run: flutter pub run build_runner build
// to generate lib/teleport_router.gr.dart

/// Simple page demonstrating @TeleportRoute annotation.
@TeleportRoute()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Text('teleport_router_generator example'),
      ),
    );
  }
}

// After running build_runner, you'll get a generated HomeRoute class
// that can be used like: HomeRoute().teleport()
//
// For a complete working example, see:
// https://github.com/lwj1994/teleport_router/tree/main/teleport_router/example
