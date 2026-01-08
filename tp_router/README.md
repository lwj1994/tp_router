# TpRouter

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |

A simplified, type-safe, and annotation-driven routing library for Flutter.

**Stop maintaining routing tables manually.**
TpRouter automatically generates complex, nested routing tables based on your `NavKey` structure, offering a concise and elegant API for navigation and state management.

## Key Highlights

*   🚀 **Automatic Route Table**: Just annotate. We generate the entire routing tree, including complex nested shells, based on your `TpNavKey` associations.
*   � **Concise Type-Safe API**: Navigate with elegance.
    *   `UserRoute(id: 1).tp(context)`
    *   `MainNavKey().tp(UserRoute(id: 1))`
*   🐚 **NavKey-Driven Nesting**: Decouple your UI. Define Shells and nested routes simply by linking them to a `NavKey`. No massive route config files.
*   🗑️ **Elegant Removal**: Imperatively remove any route (even deeply nested or in the background) with our smart **Pending Pop** strategy.


---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tp_router: ^0.1.0
  tp_router_annotation: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.1.0
```

Run the generator:
```bash
dart run build_runner build
```

---

## 1. Essentials

### Define Routes
Annotate your widget. Constructor arguments are automatically mapped.

```dart
@TpRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  final int id; 
  const UserPage({required this.id, super.key});
  
  @override
  Widget build(BuildContext context) => Text('User $id');
}
```

### Initialize
Pass the generated `tpRoutes` to `TpRouter`.

```dart
// main.dart
final router = TpRouter(routes: tpRoutes);

runApp(MaterialApp.router(
  routerConfig: router.routerConfig,
));
```

---

## 2. Navigation System

TpRouter offers two ways to navigate: **Context-based** (automatic) and **Key-based** (precise).

### Context-based Navigation
Simplest way. It automatically finds the closest navigator in the widget tree.

```dart
// Push a route
UserRoute(id: 42).tp(context);

// Replace
LoginPage().tp(context, replacement: true);

// Clear history (e.g. after login)
HomePage().tp(context, clearHistory: true);

// Pop
context.tpRouter.pop();
```

### Key-based Navigation (Recommended)
Use **TpNavKey** for type-safe, accessible navigation from anywhere (even business logic).

1. **Define a Key**:
```dart
class MainNavKey extends TpNavKey {
  const MainNavKey() : super('main');
}
```

2. **Navigate using the Key**:
```dart
// Navigate specifically on the 'main' navigator
MainNavKey().tp(UserRoute(id: 42));

// Pop from 'main' navigator
MainNavKey().pop();

// Check if can pop
bool safe = MainNavKey().canPop;

// Pop until condition
MainNavKey().popUntil((route, data) => data?.routeName == UserRoute.kName);
```

---

## 3. Shell & Nested Navigation

Manage complex nested UI (like BottomNavigationBar) with **Shell Routes**.

### Define a Shell
Associate a `navigatorKey` with a shell.

```dart
@TpShellRoute(
  navigatorKey: MainNavKey, // Defined above
  isIndexedStack: true,     // Persist state of tabs
)
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;
  // ... build BottomNavigationBar using navigationShell
}
```

### Assign Routes to Shell
Use `parentNavigatorKey` to place a route inside a shell.

```dart
@TpRoute(path: '/home', parentNavigatorKey: MainNavKey, branchIndex: 0)
class HomePage extends StatelessWidget { ... }

@TpRoute(path: '/settings', parentNavigatorKey: MainNavKey, branchIndex: 1)
class SettingsPage extends StatelessWidget { ... }
```

---

## 4. Advanced Features

### Route Management
Imperatively manage the stack, even for declarative routers like GoRouter.

```dart
// Remove specific route instance
context.tpRouter.removeRoute(myRouteData);

// Remove using predicate (e.g., clear all dialogs)
context.tpRouter.removeWhere((data) => data.fullPath.contains('/dialog'));
```

### Guards & Redirects
Type-safe redirection logic.

```dart
class AuthGuard extends TpRedirect<ProtectedRoute> {
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, ProtectedRoute route) {
    if (!loggedIn) return const LoginRoute();
    return null; // Allowed
  }
}

@TpRoute(path: '/protected', redirect: AuthGuard)
class ProtectedPage extends StatelessWidget { ... }
```

### Route Lifecycle (onExit)
Intercept back navigation (e.g., unsaved changes).

```dart
class UnsavedChangesGuard extends TpOnExit<EditorRoute> {
  @override
  FutureOr<bool> onExit(BuildContext context, EditorRoute route) async {
    return await showDialog(...) ?? false;
  }
}

@TpRoute(path: '/edit', onExit: UnsavedChangesGuard)
class EditorPage extends StatelessWidget { ... }
```

### Runtime Parameters
Access current route data anytime.

```dart
// Get current path on a specific navigator
String path = MainNavKey().currentFullPath;
```

---

## Configuration

Customize generation output in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/routes.gr.dart
```

## Migration Guide
See [MIGRATION.md](MIGRATION.md).
