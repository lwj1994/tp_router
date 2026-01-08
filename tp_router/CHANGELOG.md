## 0.4.1

*   **Fix**: Improved `didReplace` logic in `TpRouteObserver` to correctly handle route replacements and maintain proper synchronization with the internal route list.
*   **Fix**: `allRouteData` getter now returns a `Map<Route, TpRouteData>` sorted by the route's position in the navigation stack (bottom to top).
*   **Fix**: Simplified `pop` and `canPop` methods to directly use `Navigator` state.
*   **Fix**: Refactored `removeRoute` to handle edge cases when the route to be removed is the current route.
*   **API**: The `location` getter now returns a `TpRouteData` object instead of a raw `String` path, providing structured route information via `fullPath`.

## 0.4.0

*   **Type-Safe NavKeys**: Introduced `TpNavKey` class for strong-typed navigator keys. Deprecated usage of raw Strings for navigator keys in favor of `TpNavKey` subclasses.
*   **Security**: Enhanced `TpRouter.tp()` to enforce mutual exclusivity between `context` and `navigatorKey`.

## 0.3.0
*   **🔄 Breaking Change: Class-based Callbacks**
    *   Refactored `onExit` and `redirect` in `@TpRoute` to use a class-based approach. Users now implement `TpOnExit<T>` and `TpRedirect<T>` interfaces.
    *   Annotation parameters `onExit` and `redirect` now accept `Type`.
*   **🛠️ Improvements: Type Safety & Reconstruction**
    *   Added `static T fromData(TpRouteData)` to generated route classes for safe reconstruction of strongly-typed route objects.
    *   The generated `redirect` and `onExit` callbacks now automatically use `fromData` to ensure provide a valid typed instance, even if navigated via raw path or `fromPath`.
*   ** PREMIUM Experience: Swipe Back**
    *   Improved `TpPageType.swipeBack` with full-screen gesture support (by default).
    *   Added smooth shadow animations and conflict detection (ignores swipe if child scrolls horizontal).
*   **🐚 Shell Route Cleanup**
    *   Removed transition configuration from `@TpShellRoute`. Shells now use `TpNoTransition` by default to avoid redundant animations.
*   **📝 API Refinement**
    *   Made `TpRouteData.routeName` nullable to better represent unnamed routes.
    *   Updated `removeRoute` logic to gracefully handle unnamed routes.

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
