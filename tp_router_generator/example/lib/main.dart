import 'package:flutter/material.dart';
import 'package:tp_router_annotation/tp_router_annotation.dart';

// This is a minimal example showing annotation usage.
// Run: flutter pub run build_runner build
// to generate lib/tp_router.gr.dart

/// Simple page demonstrating @TpRoute annotation.
@TpRoute()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Text('tp_router_generator example'),
      ),
    );
  }
}

// After running build_runner, you'll get a generated HomeRoute class
// that can be used like: HomeRoute().tp()
//
// For a complete working example, see:
// https://github.com/lwj1994/tp_router/tree/main/tp_router/example
