## 0.2.0
*   **✨ New Features: Smart Route Removal**
    *   Added `context.tpRouter.removeRoute()` and `removeWhere()`.
    *   **Pinpoint Deletion**: Remove routes from specific navigators using `navigatorKey` or `context` scope.
    *   **Pending Pop Strategy**: Implemented "Smart Remove" to safely delete go_router pages (including background pages) without crashing, by auto-skipping them on back navigation.
    *   Robust handling of route updates and memory cleanup via enhanced `TpRouteObserver`.

## 0.1.1

* Updated go_router dependency to ^17.0.1.
* Documentation improvements and bug fixes.

## 0.1.0


* Changed `TpRouteData.extra` type from `Map<String, dynamic>` to `dynamic` for flexibility.
* Improved type handling for complex extra parameters.

## 0.0.2
* update doc
## 0.0.1

* Initial release.
* Core routing logic based on `go_router`.
* Support for `TpRouteData` and generated route classes.
* Type-safe navigation API (`.tp()`).
* Support for parameter extraction from Path, Query, and Extra.
* Comprehensive route guard/redirect system using `TpRedirect`.
* Nested navigation support via `ShellRoute`.
* Support for global and per-route transition configuration.
