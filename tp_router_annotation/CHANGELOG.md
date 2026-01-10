## 0.6.2

*   **Version Bump**: Synchronize version with `tp_router` 0.6.2.

## 0.6.1

*   **Version Bump**: Synchronize version with `tp_router` 0.6.1 for consistency.

## 0.5.0

*   **Breaking Change**: Removed `branchIndex` from `TpRoute` and `TpShellRoute`. Branch membership is now inferred via `parentNavigatorKey` in `branchKeys`.

## 0.4.0

*   **Breaking Change**: Changed `navigatorKey` in `TpShellRoute` and `parentNavigatorKey` in `TpRoute` from `String` to `Type` to support type-safe NavKeys.

## 0.3.0

*   **🔄 Breaking Change**: Changed `onExit` and `redirect` fields in `@TpRoute` from function type to `Type?`.
*   **🐚 Shell Route Cleanup**: Removed `transition`, `transitionDuration`, and `reverseTransitionDuration` from `@TpShellRoute`. Shells are now treated as transparent UI wrappers.
*   Removed `TpOnExit` and `TpRedirect` abstract classes (moved to `tp_router` package).

## 0.1.1

* Documentation improvements and package metadata updates.
* Added repository and issue tracker URLs.

## 0.1.0


* Improved `TpShellRoute` documentation with examples for both modes.
* Added detailed API documentation for `isIndexedStack` parameter.

## 0.0.1

* Initial release.
* Define `TpRoute` for route definition.
* Define `TpShellRoute` and `TpStatefulShellRoute` for nested navigation.
* Provide `Path` and `Query` annotations for parameter extraction.
* Support function and class based `redirect` configuration.
