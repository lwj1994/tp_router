/// Export all public APIs from tp_router.
library tp_router;

// Re-export annotations from tp_router_annotation
export 'package:tp_router_annotation/tp_router_annotation.dart';

// Export router implementation
export 'src/tp_route_info.dart';
export 'src/tp_router.dart';
export 'src/route.dart';
export 'src/route_observer.dart';
export 'src/transitions.dart';
