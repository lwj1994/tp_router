/// Export all public APIs from teleport_router.
library teleport_router;

// Re-export annotations from teleport_router_annotation
export 'package:teleport_router_annotation/teleport_router_annotation.dart';

// Export router implementation
export 'src/teleport_route_info.dart'
    show
        TeleportStatefulNavigationShell,
        TeleportRouteInfo,
        TeleportShellRouteInfo,
        TeleportParamInfo,
        TeleportRouteBase,
        TeleportRedirect,
        TeleportOnExit,
        TeleportStatefulShellRouteInfo;
export 'src/teleport_router.dart';
export 'src/route.dart';
export 'src/page_factory.dart';
export 'src/transitions.dart';
export 'src/navi_key.dart' show TeleportNavKey;
export 'src/context_extension.dart';
