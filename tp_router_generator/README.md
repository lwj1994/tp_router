# tp_router_generator

[![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator)

Code generator for [tp_router](https://pub.dev/packages/tp_router) - A Flutter package that provides type-safe, annotation-based routing built on top of go_router.

## Overview

`tp_router_generator` processes `@TpRoute`, `@TpShellRoute`, and `@TpStatefulShellRoute` annotations to automatically generate type-safe routing code. It eliminates boilerplate and ensures compile-time safety for your navigation logic.

## Installation

Add to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dependencies:
  tp_router: any

dev_dependencies:
  build_runner: any
 tp_router_generator: any
```

## Usage

### 1. Annotate Your Pages

```dart
import 'package:tp_router_annotation/tp_router_annotation.dart';

@TpRoute()
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
HomeRoute().tp(context);

// With parameters
UserRoute(userId: '123').tp(context);
```

## Generated Code

The generator creates:

- **Type-safe route classes**: One for each `@TpRoute` annotated page
- **Parameter extraction**: Automatic handling of path, query, and extra parameters
- **Route configuration**: `TpRouteInfo` objects for go_router integration  
- **Global route list**: `tpRoutes` containing all routes in your app

## Configuration

Customize the output file location in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/generated/routes.g.dart
```

## Features

- ✅ Generates type-safe route classes (e.g., `HomeRoute`, `UserRoute`)
- ✅ Handles parameter extraction from path, query, and extra data
- ✅ Supports custom transitions and global configuration
- ✅ Supports shell routes (`TpShellRoute`, `TpStatefulShellRoute`)
- ✅ Compile-time validation of route parameters
- ✅ Automatic path generation from class names

## Related Packages

- **[tp_router](https://pub.dev/packages/tp_router)** - Main routing package
- **[tp_router_annotation](https://pub.dev/packages/tp_router_annotation)** - Annotation definitions

## Example

See the [tp_router example](https://github.com/lwj1994/tp_router/tree/main/tp_router/example) for a complete working application demonstrating all features.



## License

See the main [tp_router repository](https://github.com/lwj1994/tp_router) for license information.
