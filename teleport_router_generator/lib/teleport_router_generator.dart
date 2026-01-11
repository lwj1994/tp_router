/// Code generation library for teleport_router.
///
/// This library provides the [TeleportRouterBuilder] that processes `@TeleportRoute`,
/// `@TeleportShellRoute`, and `@TeleportStatefulShellRoute` annotations to generate
/// type-safe routing code for Flutter applications.
///
/// ## Usage
///
/// This package is designed to be used with [build_runner]. Add it to your
/// `dev_dependencies`:
///
/// ```yaml
/// dev_dependencies:
///   build_runner: any
///   teleport_router_generator: any
/// ```
///
/// Then run:
///
/// ```bash
/// flutter pub run build_runner build
/// ```
///
/// For more information and complete examples, see the
/// [teleport_router](https://pub.dev/packages/teleport_router) package documentation.
library teleport_router_generator;

export 'src/teleport_route_generator.dart';
