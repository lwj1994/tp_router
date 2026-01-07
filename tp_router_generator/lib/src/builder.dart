import 'package:build/build.dart';
import 'tp_route_generator.dart';

/// Creates a [Builder] instance for generating tp_router code.
///
/// This factory function is called by [build_runner] to create the builder
/// that processes `@TpRoute` annotations and generates the routing code file.
///
/// ## Configuration
///
/// The builder accepts the following configuration options via [BuilderOptions]:
///
/// - `output`: The path for the generated file. Defaults to `lib/tp_router.gr.dart`.
///
/// Example configuration in `build.yaml`:
///
/// ```yaml
/// builders:
///   tp_router_generator:
///     options:
///       output: lib/generated/routes.g.dart
/// ```
///
/// ## Generated Output
///
/// The builder scans all Dart files in the build target for classes annotated
/// with `@TpRoute`, `@TpShellRoute`, or `@TpStatefulShellRoute`, then generates:
///
/// - Type-safe route classes for navigation (e.g., `HomeRoute`, `UserRoute`)
/// - Route data extraction from path parameters, query parameters, and extra data
/// - Shell route configurations for nested navigation
///
/// Returns a [TpRouterBuilder] instance configured with the specified options.
Builder tpRouterBuilder(BuilderOptions options) {
  final output = options.config['output'] as String? ?? 'lib/tp_router.gr.dart';
  return TpRouterBuilder(output: output);
}
