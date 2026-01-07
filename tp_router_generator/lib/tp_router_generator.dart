/// Code generation library for tp_router.
///
/// This library provides the [TpRouterBuilder] that processes `@TpRoute`,
/// `@TpShellRoute`, and `@TpStatefulShellRoute` annotations to generate
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
///   tp_router_generator: any
/// ```
///
/// Then run:
///
/// ```bash
/// flutter pub run build_runner build
/// ```
///
/// For more information and complete examples, see the
/// [tp_router](https://pub.dev/packages/tp_router) package documentation.
library tp_router_generator;

export 'src/tp_route_generator.dart';
