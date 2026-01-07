import 'package:build/build.dart';
import 'tp_route_generator.dart';

/// Builder factory for tp_router_generator.
///
/// This creates a single tp_router.gr.dart file with all routes.
Builder tpRouterBuilder(BuilderOptions options) {
  final output = options.config['output'] as String? ?? 'lib/tp_router.gr.dart';
  return TpRouterBuilder(output: output);
}
