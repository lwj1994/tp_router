# TpRouter

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |


A simplified, type-safe, and annotation-driven routing library for Flutter, built on top of `go_router`.

Stop writing boilerplate routing tables manually. Let `tp_router` handle it for you with strong typing and compile-time safety.

## Features

*   🚀 **Annotation Driven**: Define routes directly on your widgets using `@TpRoute`.
*   🛡️ **Type-Safe Parsing**: Automatically extracts `int`, `double`, `bool`, `String`, and complex objects from path, query parameters, or extra data.
*   🔄 **Smart Redirection**: Strong-typed redirection mechanism. Check parameters before navigating.
*   🐚 **Shell Routes & Nested Navigation**: Full support for `ShellRoute` and `StatefulShellRoute` (IndexedStack).
*   ⚡ **Simple Navigation API**: Just call `MyRoute().tp(context)`.

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  tp_router: ^0.1.0
  tp_router_annotation: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.1.0
```

## Getting Started

### 1. Define Your Routes

Annotate your widget with `@TpRoute`. 
Constructor arguments are automatically mapped to route parameters!

```dart
// lib/pages/user_page.dart
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  // Automatically mapped from path parameter ':id'
  // Or query parameter 'id', or extra data 'id'.
  final int id; 
  
  // Optional parameter with default value
  final String section; 

  const UserPage({
    required this.id,
    this.section = 'profile',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('User $id - Section $section');
  }
}
```

### 2. Generate Code

Run the build runner to generate the routing table:

```bash
dart run build_runner build
```

This will generate `lib/tp_router.gr.dart` (default path).

### 3. Initialize Router

In your `main.dart`, initialize `TpRouter` with the generated routes list.

```dart
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import 'tp_router.gr.dart'; // Import generated file

void main() {
  final router = TpRouter(
    routes: tpRoutes, // Generated list of routes
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

---

## Navigation

Navigate using the generated route classes. This is 100% type-safe.

```dart
// Push a new route
UserPage(id: 42).tp(context);

// Replace the current route
LoginPage().tp(context, replacement: true);

// Clear history and go to new route
HomePage().tp(context, clearHistory: true);

// Wait for a result
final result = await SelectProfileRoute().tp<String>(context);
```

You can also pop:
```dart
context.tpRouter.pop('Some Result');
```

---

## Capabilities

### Parameter Extraction Strategy
TpRouter smartly resolves constructor parameters in this order:
1.  **Explicit Annotation**: `@Path('id')` (Force path param) or `@Query('q')` (Force query param).
2.  **Extra Data**: Checks if the object was passed via `extra` map.
3.  **Path Parameters**: Checks if the URL path contains the key.
4.  **Query Parameters**: Checks the URL query string.

### Redirection / Guards

TpRouter supports a powerful, type-safe redirection system. 
You can define a redirect function or class that receives the **fully instantiated route object**.

**1. Define a Redirect Logic**
```dart
// You can access 'route.id' directly!
FutureOr<TpRouteData?> checkUserAccess(BuildContext context, UserRoute route) {
  if (route.id == 999) {
    // Redirect to blocked page
    return const BlockedRoute();
  }
  return null; // No redirect, proceed to page
}
```

**2. Attach to Route**
```dart
@TpRoute(path: '/user/:id', redirect: checkUserAccess)
class UserPage extends StatelessWidget { ... }
```

You can also use a class extending `TpRedirect<T>` for cleaner organization.

```dart
class AuthRedirect extends TpRedirect<ProtectedRoute> {
  const AuthRedirect();
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, ProtectedRoute route) {
    if (!AuthService.isLoggedIn) {
      return const LoginRoute();
    }
    return null;
  }
}

@TpRoute(path: '/protected', redirect: AuthRedirect)
class ProtectedPage extends StatelessWidget { ... }
```

### Shell Routes (Nested Navigation)

TpRouter provides a powerful and decoupled way to define shell routes using **keys**. Instead of manually listing children, you simply assign a `navigatorKey` to a shell and associate child routes using `parentNavigatorKey`.

This approach keeps your code clean and modular, perfect for complex apps!

#### 1. Define a Shell Route
Assign a unique `navigatorKey` to your shell layout.

```dart
// Stateful Shell (e.g., BottomNavigationBar)
@TpShellRoute(
  navigatorKey: 'main', 
  isIndexedStack: true, // Preserves state of each branch
)
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;
  
  const MainShellPage({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        // Helper method to switch branches
        onTap: (index) => navigationShell.goBranch(index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

#### 2. Associate Child Routes
Simply add `parentNavigatorKey` to any route that belongs to a shell.
For stateful shells (tabs), use `branchIndex` to assign the route to a specific tab.

```dart
// Branch 0: Home
@TpRoute(path: '/', parentNavigatorKey: 'main', branchIndex: 0)
class HomePage extends StatelessWidget { ... }

// Branch 1: Settings
@TpRoute(path: '/settings', parentNavigatorKey: 'main', branchIndex: 1)
class SettingsPage extends StatelessWidget { ... }
```

#### 3. Nested Shells (Advanced)
You can even nest a shell inside another shell! Just treat the inner shell as a child of the outer shell.

```dart
// A shell inside the 'main' shell's 3rd branch
@TpShellRoute(
  navigatorKey: 'dashboard',   // This shell's own key
  parentNavigatorKey: 'main',  // Parent shell's key
  branchIndex: 2,              // Place in branch 2 of 'main'
)
class DashboardShell extends StatelessWidget { ... }

// Children of the nested 'dashboard' shell
@TpRoute(path: '/dashboard/stats', parentNavigatorKey: 'dashboard')
class StatsPage extends StatelessWidget { ... }
```

#### 4. Configure Page and Transitions
You can customize page behavior, transitions, and observers for Shell Routes just like regular routes.

```dart
@TpShellRoute(
  navigatorKey: 'modal_shell',
  // Make the shell transparent (e.g. for dialogs)
  opaque: false, 
  // Add a custom transition
  transition: TpFadeTransition,
  transitionDuration: Duration(milliseconds: 300),
  // Add observers
  observers: [MyObserver],
)
class ModalShellPage extends StatelessWidget { ... }
```

---

## Configuration

### Custom Output Path

By default, code is generated in `lib/tp_router.gr.dart`. You can customize this in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/router/route.gr.dart
```

---

## Migration Guide

Thinking about switching from `go_router` or `auto_router`? Check out our [Migration Guide](https://github.com/lwj1994/tp_router/blob/main/tp_router/MIGRATION.md).

## License
