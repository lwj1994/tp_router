# Migration Guide

This guide helps you migrate from `go_router` or `auto_router` to `teleport_router`.

---

## 1. Migrating from go_router

`teleport_router` is built as a wrapper around `go_router`. While the underlying capabilities are consistent, the configuration and API are significantly simplified.

### Configuration

*   **go_router**: Requires maintaining a centralized `GoRouter` instance and manually extracting parameters from `state.pathParameters` or `state.uri`.

```dart
// go_router
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/user/:id',
      builder: (context, state) => UserPage(
        id: int.parse(state.pathParameters['id']!),
        name: state.uri.queryParameters['name'],
      ),
    ),
  ],
);
```

*   **teleport_router**: Defined directly on the Widget via an annotation. Parameters are automatically parsed and cast.

```dart
// teleport_router
@TeleportRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  final int id; // Automatically parsed from :id and cast to int
  final String? name; // Automatically fetched from query parameters

  const UserPage({required this.id, this.name});
}

// Initialize with the generated route list
final router = TeleportRouter(routes: teleportRoutes);
```

### Navigation API

*   **go_router**: Relies on string paths. Prone to typos and lacks compile-time safety for required arguments.

```dart
context.push('/user/42?name=Alice');
```

*   **teleport_router**: Uses generated route classes. Ensures all required parameters are provided at compile-time.

```dart
UserRoute(id: 42, name: 'Alice').teleport(context);
```

### Redirection

*   **go_router**: Uses global closures where you must manually parse the URL state.
*   **teleport_router**: Provides access to the **fully instantiated** route object within the redirect handler.

---

## 2. Migrating from auto_router

`teleport_router` offers a similar annotation-based experience to `auto_router` but is much more lightweight and integrates natively with the `go_router` ecosystem.

### Route Definition

*   **auto_router**: Requires `@RoutePage()` on Widgets AND a manual declaration of all routes in a central `AppRouter` class.
*   **teleport_router**: Requires only the `@TeleportRoute` annotation. No central registry collection is needed; the generator handles it automatically.

### Parameter Mapping

*   **auto_router**: Uses custom annotations like `@PathParam`.
*   **teleport_router**: Uses smart matching based on constructor parameter names by default, with optional `@Path` and `@Query` overrides.

### Nested Routes

*   **auto_router**: Uses `AutoTabsRouter` or similar specific implementations.
*   **teleport_router**: Uses standard `@TeleportShellRoute` or `@TeleportStatefulShellRoute`. The generated `navigationShell` provides a familiar API for switching branches.

---

## Comparison Summary

| Feature | go_router | auto_router | teleport_router |
|---|---|---|---|
| **Definition** | Manual Registry | Annotations + Registry | **Decentralized Annotations** |
| **Params** | Manual Parsing | Automatic (Annotation required) | **Automatic (Smart Match)** |
| **Navigation** | String-based | Class-based | **Class-based** |
| **Underlying** | Native | Custom Wrapper | **Native Wrapper (go_router compatible)** |
| **Overhead** | High (Boilerplate) | High (Complexity) | **Minimal** |
