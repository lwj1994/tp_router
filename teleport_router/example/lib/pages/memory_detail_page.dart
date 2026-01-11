import 'package:flutter/material.dart';
import '../widgets/location_display.dart';
import 'package:teleport_router/teleport_router.dart';
import '../models/memory_detail.dart';

@TeleportRoute(path: '/memory-detail')
class MemoryDetailPage extends StatelessWidget {
  final MemoryDetail memory;
  final MemoryDetail memory2;

  const MemoryDetailPage({
    super.key,
    required this.memory2,
    this.memory =
        const MemoryDetail(id: 'internal', content: 'Internal Default'),
  });

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      child: Scaffold(
        appBar: AppBar(title: const Text('Memory Detail')),
        body: Center(
          child: Text('Memory: $memory'),
        ),
      ),
    );
  }
}
