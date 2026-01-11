import 'package:example/routes/nav_keys.dart';
import 'package:flutter/material.dart';
import '../widgets/location_display.dart';
import 'package:teleport_router/teleport_router.dart';

/// User page demonstrating parameter extraction.
///
/// Parameters:
/// - id: Path parameter (required int)
/// - name: Query parameter (required String)
/// - age: Query parameter (required int)
///
/// Usage:
/// ```dart
/// context.teleportRouter.pushPath('/user/123?name=John&age=25');
/// // or type-safe:
/// // UserRoute(id: 123, name: 'John', age: 25).teleport();
/// ```
@TeleportRoute(
  path: '/user/:id',
  parentNavigatorKey: MainHomeNavKey,
)
class UserPage extends StatelessWidget {
  /// User ID from path parameter.
  @Path('id')
  final int id;

  /// User name from query parameter.
  @Query()
  final String name;

  /// User age from query parameter.
  @Query()
  final int age;

  const UserPage({
    required this.id,
    this.name = '',
    this.age = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => TeleportRouter.instance.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: $id', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Name: $name',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Age: $age', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              const Text(
                'These parameters were automatically extracted and '
                'type-converted from the URL!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
