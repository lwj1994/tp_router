# teleport_router_generator

[![pub package](https://img.shields.io/pub/v/teleport_router_generator.svg)](https://pub.dev/packages/teleport_router_generator)

Code generator for [teleport_router](https://pub.dev/packages/teleport_router) - A Flutter package that provides type-safe, annotation-based routing built on top of go_router.

## Overview

`teleport_router_generator` processes `@TeleportRoute`, `@TeleportShellRoute`, and `@TeleportStatefulShellRoute` annotations to automatically generate type-safe routing code. It eliminates boilerplate and ensures compile-time safety for your navigation logic.

## Installation

Add to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dependencies:
  teleport_router: any

dev_dependencies:
  build_runner: any
 teleport_router_generator: any
```

## Usage

### 1. Annotate Your Pages

```dart
import 'package:teleport_router_annotation/teleport_router_annotation.dart';

@TeleportRoute()
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  // ... widget implementation
}
```

### 2. Run Code Generation

```bash
# One-time generation
flutter pub run build_runner build

# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch

# Delete conflicting outputs and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Use Generated Routes

After generation, you'll get type-safe route classes:

```dart
// Navigate using generated route
HomeRoute().teleport(context);

// With parameters
UserRoute(userId: '123').teleport(context);
```

## Generated Code

The generator creates:

- **Type-safe route classes**: One for each `@TeleportRoute` annotated page
- **Parameter extraction**: Automatic handling of path, query, and extra parameters
- **Route configuration**: `TeleportRouteInfo` objects for go_router integration  
- **Global route list**: `teleportRoutes` containing all routes in your app
- **Static `fromData` method**: Reconstruct typed route instances from generic data objects
- **Class-based Callbacks**: Support for `TeleportRedirect` and `TeleportOnExit` implementations

## Configuration

Customize the output file location in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      teleport_router_generator:
        options:
          output: lib/generated/routes.g.dart
```

## Features

- ✅ Generates type-safe route classes (e.g., `HomeRoute`, `UserRoute`)
- ✅ Handles parameter extraction from path, query, and extra data
- ✅ Supports custom transitions and global configuration
- ✅ Supports shell routes (`TeleportShellRoute`, `TeleportStatefulShellRoute`)
- ✅ Compile-time validation of route parameters
- ✅ Static reconstruction via `fromData` method
- ✅ Class-based redirection and lifecycle guards
- ✅ Automatic path generation from class names

## Related Packages

- **[teleport_router](https://pub.dev/packages/teleport_router)** - Main routing package
- **[teleport_router_annotation](https://pub.dev/packages/teleport_router_annotation)** - Annotation definitions

## Example

See the [teleport_router example](https://github.com/lwj1994/teleport_router/tree/main/teleport_router/example) for a complete working application demonstrating all features.



## License

See the main [teleport_router repository](https://github.com/lwj1994/teleport_router) for license information.
