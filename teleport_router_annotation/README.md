# teleport_router_annotation

Annotations for [teleport_router](https://pub.dev/packages/teleport_router), to enable type-safe route generation.

This package defines the annotations used to configure routes, shell routes, and redirection logic.

## Annotations

*   `@TeleportRoute`: Define a route.
*   `@TeleportShellRoute`: Define a shell route (wrapper).
*   `@TeleportStatefulShellRoute`: Define a stateful shell route (e.g. IndexedStack).
*   `@Path`: Explicitly map a constructor parameter to a path parameter.
*   `@Query`: Explicitly map a constructor parameter to a query parameter.
