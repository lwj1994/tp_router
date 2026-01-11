# teleport_router_generator Example

This directory contains a minimal example demonstrating how to use `teleport_router_generator` as a dev dependency.

## About Code Generators

`teleport_router_generator` is a **code generator** used via `build_runner`. It doesn't contain runnable application code. Instead, it processes annotations in your code to generate routing boilerplate.

## Usage

This example shows the basic setup:

1. Add dependencies in `pubspec.yaml`
2. Annotate pages with `@TeleportRoute`
3. Run `flutter pub run build_runner build`

## Complete Example

For a full, working example of `teleport_router` in action, see the main package example:

**[teleport_router/example](../../teleport_router/example/)**

The main example demonstrates:
- Multiple annotated routes
- Path and query parameters
- Shell routes and nested navigation
- Custom transitions
- Complete application structure

## Running Code Generation

```bash
flutter pub get
flutter pub run build_runner build
```

This will generate `lib/teleport_router.gr.dart` with type-safe route classes.
