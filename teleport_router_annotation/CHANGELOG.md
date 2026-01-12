## 0.8.0
* **Sync**: Synchronize version with `teleport_router` 0.8.0.

## 0.7.2
* **Sync**: Synchronize version with `teleport_router` 0.7.2.

## 0.7.1
* **Sync**: Synchronize version with `teleport_router` 0.7.1.

## 0.7.0
* **Rename**: Successfully renamed `tp_router_annotation` to `teleport_router_annotation`.
* **Refactor**: All `Tp` prefixed annotations and classes have been updated to `Teleport`.

## 0.6.2


*   **Version Bump**: Synchronize version with `teleport_router` 0.6.2.

## 0.6.1

*   **Version Bump**: Synchronize version with `teleport_router` 0.6.1 for consistency.

## 0.5.0

*   **Breaking Change**: Removed `branchIndex` from `TeleportRoute` and `TeleportShellRoute`. Branch membership is now inferred via `parentNavigatorKey` in `branchKeys`.

## 0.4.0

*   **Breaking Change**: Changed `navigatorKey` in `TeleportShellRoute` and `parentNavigatorKey` in `TeleportRoute` from `String` to `Type` to support type-safe NavKeys.

## 0.3.0

*   **🔄 Breaking Change**: Changed `onExit` and `redirect` fields in `@TeleportRoute` from function type to `Type?`.
*   **🐚 Shell Route Cleanup**: Removed `transition`, `transitionDuration`, and `reverseTransitionDuration` from `@TeleportShellRoute`. Shells are now treated as transparent UI wrappers.
*   Removed `TeleportOnExit` and `TeleportRedirect` abstract classes (moved to `teleport_router` package).

## 0.1.1

* Documentation improvements and package metadata updates.
* Added repository and issue tracker URLs.

## 0.1.0


* Improved `TeleportShellRoute` documentation with examples for both modes.
* Added detailed API documentation for `isIndexedStack` parameter.

## 0.0.1

* Initial release.
* Define `TeleportRoute` for route definition.
* Define `TeleportShellRoute` and `TeleportStatefulShellRoute` for nested navigation.
* Provide `Path` and `Query` annotations for parameter extraction.
* Support function and class based `redirect` configuration.
