import 'package:build/build.dart';
import 'teleport_route_generator.dart';

/// Creates a [Builder] instance for generating teleport_router code.
///
/// This factory function is called by [build_runner] to create the builder
/// that processes `@TeleportRoute` annotations and generates the routing code file.
///
/// ## Configuration
///
/// The builder accepts the following configuration options via [BuilderOptions]:
///
/// - `output`: The path for the generated file. Defaults to `lib/teleport_router.gr.dart`.
///
/// Example configuration in `build.yaml`:
///
/// ```yaml
/// builders:
///   teleport_router_generator:
///     options:
///       output: lib/generated/routes.g.dart
/// ```
///
/// ## Generated Output
///
/// The builder scans all Dart files in the build target for classes annotated
/// with `@TeleportRoute`, `@TeleportShellRoute`, or `@TeleportStatefulShellRoute`, then generates:
///
/// - Type-safe route classes for navigation (e.g., `HomeRoute`, `UserRoute`)
/// - Route data extraction from path parameters, query parameters, and extra data
/// - Shell route configurations for nested navigation
///
/// Returns a [TeleportRouterBuilder] instance configured with the specified options.
Builder teleportRouterBuilder(BuilderOptions options) {
  final output =
      options.config['output'] as String? ?? 'lib/teleport_router.gr.dart';
  return TeleportRouterBuilder(output: output);
}
