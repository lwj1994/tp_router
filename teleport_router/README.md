# TeleportRouter

> **Teleport — like in League of Legends. Click and you're there.** 
> It's catchy, instant, and fits the theme of seamless navigation. just call `MyRoute().teleport()` and you're at your destination.


[中文文档](README_zh.md)

| Package | Version |
|---------|---------|
| [teleport_router](https://pub.dev/packages/teleport_router) | [![pub package](https://img.shields.io/pub/v/teleport_router.svg)](https://pub.dev/packages/teleport_router) |
| [teleport_router_annotation](https://pub.dev/packages/teleport_router_annotation) | [![pub package](https://img.shields.io/pub/v/teleport_router_annotation.svg)](https://pub.dev/packages/teleport_router_annotation) |
| [teleport_router_generator](https://pub.dev/packages/teleport_router_generator) | [![pub package](https://img.shields.io/pub/v/teleport_router_generator.svg)](https://pub.dev/packages/teleport_router_generator) |

**A simplified, type-safe, and annotation-driven routing library for Flutter.**

TeleportRouter is built on top of [go_router](https://pub.dev/packages/go_router)—the official Flutter routing package. This means you get all the battle-tested features (deep linking, web support, nested navigation) without worrying about core stability. TeleportRouter simply provides a more ergonomic, annotation-based API that eliminates boilerplate and enables type-safe navigation.

---

## Table of Contents

- [Features](#-features)
- [Core Concepts](#-core-concepts)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
  - [1. Define NavKeys](#1-define-navkeys)
  - [2. Define Shells](#2-define-shells)
  - [3. Define Routes](#3-define-routes)
  - [4. Initialize Router](#4-initialize-router)
- [Navigation](#-navigation)
  - [Type-Safe Navigation](#type-safe-navigation)
  - [Pop & Stack Control](#pop--stack-control)
- [Parameters](#-parameters)
  - [Path Parameters](#path-parameters)
  - [Query Parameters](#query-parameters)
  - [Extra (Complex Objects)](#extra-complex-objects)
  - [Combined Example](#combined-example)
- [Guards & Redirects](#-guards--redirects)
  - [Route-Level Redirect](#route-level-redirect)
  - [Global Redirect](#global-redirect)
  - [Reactive Routing (refreshListenable)](#reactive-routing-refreshlistenable)
- [Route Lifecycle](#-route-lifecycle)
  - [OnExit Guard](#onexit-guard)
- [Deep Linking](#-deep-linking)
- [Page Transitions](#-page-transitions)
  - [Built-in Transitions](#built-in-transitions)
  - [Custom Transitions](#custom-transitions)
  - [Swipe Back](#swipe-back)
- [Page Configuration](#-page-configuration)
  - [Page Type (TeleportPageType)](#page-type-tppagetype)
  - [Dialog & Modal Options](#dialog--modal-options)
  - [Transparent Pages](#transparent-pages)
  - [Full Annotation Reference](#full-annotation-reference)
- [Configuration](#-configuration)
  - [TeleportRouter Options](#tprouter-options)
  - [build.yaml Options](#buildyaml-options)

---

## ✨ Features

- **🗝️ NavKey-Driven Linking**: No more nesting hell. Just tell a route "My parent is `MainNavKey`", and they are automatically linked.
- **📐 Type-Safe Navigation**: `UserRoute(id: 1).teleport()` instead of string manipulation.
- **🐚 Simple Shells**: Define app layouts (BottomNav, Drawers) purely through annotations.
- **🛡️ Type-Safe Guards**: Strongly-typed `TeleportRedirect<T>` for route protection.
- **🔄 Reactive Routing**: Use `refreshListenable` to auto-redirect on state changes.
- **🧩 Smart Code Gen**: Automatically handles parameters, return values, and deep linking.

---

## 🧩 Core Concepts

Understanding how TeleportRouter works helps you leverage its full power.

### 1. The Triad of Navigation
TeleportRouter connects three key pieces:
- **Routes (`@TeleportRoute`)**: Static configuration of *what* screens you have.
- **Generator**: Converts annotations into strongly-typed classes (`UserRoute`, `HomeRoute`).
- **Router (`TeleportRouter`)**: The runtime engine that manages the navigation stack using `go_router`.

### 2. TeleportNavKey: The Bridge
`TeleportNavKey` is more than just a `GlobalKey`. It is the **binding agent** that connects:
- A Shell (UI container)
- A Navigator (Flutter's navigation stack)
- An Observer (TeleportRouter's tracking system)

When you define `class MainKey extends TeleportNavKey`, you are creating a unique identifier that ensures your `ShellRoute` uses the *exact same* navigator instance that your `routes` are trying to navigate into.

### 3. Smart Observation
TeleportRouter automatically injects `TeleportRouteObserver` into every navigator managed by a `TeleportNavKey` (especially in ShellRoutes). This observer tracks the live route stack, enabling advanced features like:
- `popUntil(predicate)`
- `popToInitial()`
- `removeWhere()`

Normal `go_router` doesn't easily support these because it manages URLs, not Flutter Route objects. TeleportRouter bridges this gap by watching the actual `Navigator` activities.

### 4. Architecture Deep Dive
TeleportRouter is designed as a compile-time abstraction layer over `go_router`.

| Layer | Component | Role |
|-------|-----------|------|
| **User Code** | Annotations (`@TeleportRoute`) | Define the navigation structure and parameters declaratively. |
| **Build System** | `teleport_router_generator` | Analyzes code and generates type-safe `Route` classes. |
| **Runtime** | `TeleportRouteData` | The common interface for all routes. It unifies parameters (path, query, extra) into a single API. |
| **Core** | `TeleportRouter` | A singleton wrapper adjusting `go_router` configuration and managing global state. |
| **Engine** | `go_router` | Handles URL parsing, deep linking, and low-level navigation. |

**Data Flow:**
1.  **Code Gen**: Annotated `UserPage(id)` becomes `UserRoute(id)`.
2.  **Navigation**: Calling `UserRoute(id: 123).teleport()` converts the object into a URL path (`/user/123`) and extra data.
3.  **Routing**: `TeleportRouter` tells `go_router` to navigate.
4.  **Reconstruction**: When the page builds, `TeleportRouter` uses `TeleportRouteData.of(context)` to parse the URL/Web State back into usable data.

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  teleport_router: ^0.5.1
  teleport_router_annotation: ^0.5.0

dev_dependencies:
  build_runner: ^2.4.0
  teleport_router_generator: ^0.5.0
```

Run the generator:
```bash
dart run build_runner build
```

---

## 🚀 Quick Start

### 1. Define NavKeys

**NavKeys are the heart of TeleportRouter.** They act as unique identifiers for your navigators and bridges between parents and children.

Create a file `lib/routes/nav_keys.dart`:

```dart
import 'package:teleport_router/teleport_router.dart';

// Key for the main application shell (e.g. BottomNavigationBar)
class MainNavKey extends TeleportNavKey {
  const MainNavKey() : super('main');
}

// Sub-keys for branches if you use IndexedStack (optional but recommended)
class HomeNavKey extends TeleportNavKey {
  const HomeNavKey() : super('main', branch: 0);
}

class SettingsNavKey extends TeleportNavKey {
  const SettingsNavKey() : super('main', branch: 1);
}
```

### 2. Define Shells

Mark your container widget (e.g., a page with `BottomNavigationBar`) with `@TeleportShellRoute`.
**Link it to a key** (`MainNavKey`).

```dart
@TeleportShellRoute(
  navigatorKey: MainNavKey, // <--- Identified by this Key
  isIndexedStack: true,     // Enable stateful nested navigation
  branchKeys: [HomeNavKey, SettingsNavKey], // <--- Define branch key types (not instances)
)
class MainShellPage extends StatelessWidget {
  final TeleportStatefulNavigationShell navigationShell;
  const MainShellPage({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.teleport(index),
        items: [/* ... */],
      ),
    );
  }
}
```

### 3. Define Routes

Just annotate your pages. 
*   **To nest a page**, simply set `parentNavigatorKey` to the Shell's key.
*   **No nesting?** Omit the key.

```dart
// Standard Route (not nested)
@TeleportRoute(path: '/login')
class LoginPage extends StatelessWidget { ... }

// Nested Route (Child of MainShellPage)
@TeleportRoute(
  path: '/home',
  isInitial: true,
  parentNavigatorKey: HomeNavKey, // <--- Linked to MainShell's branch 0 automatically!
)
class HomePage extends StatelessWidget { ... }

// Another Nested Route
@TeleportRoute(
  path: '/settings',
  parentNavigatorKey: SettingsNavKey, // <--- Linked to MainShell's branch 1
)
class SettingsPage extends StatelessWidget { ... }
```

### 4. Initialize Router

Pass the generated `teleportRoutes` to `TeleportRouter`.

```dart
import 'routes/route.gr.dart';

void main() {
  final router = TeleportRouter(
    routes: teleportRoutes, // Generated by build_runner
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

---

## 🧭 Navigation

### Type-Safe Navigation

The generator creates a `Route` class for every annotated widget.

```dart
// Push a new route
UserRoute(id: 123).teleport();

// Await a result
final result = await SelectProfileRoute().teleport<String>();

// Replace current route (no back navigation)
LoginRoute().teleport(replacement: true);

// Clear history and go (like go_router's `go`)
HomeRoute().teleport(clearHistory: true);
```

### Pop & Stack Control

```dart
// Pop topmost route
context.pop();
// or with result
context.pop(result: 'selected_item');

// --- Using context extensions (Recommended) ---

// Access TeleportRouter helper via context
context.teleportRouter.popTo(HomeRoute());

context.teleportRouter.popToInitial();

// --- Using Static Instance (Global) ---

// Pop until a specific route
TeleportRouter.instance.popTo(HomeRoute());

// Pop to initial route
TeleportRouter.instance.popToInitial();

// Remove a specific route from stack (without navigating)
TeleportRouter.instance.removeRoute(SomeRoute());

// Remove routes matching condition
TeleportRouter.instance.removeWhere((data) => data.fullPath.contains('/temp'));
```

---

## 📦 Parameters

TeleportRouter provides powerful, type-safe parameter parsing.

### Path Parameters

Use `@Path()` to extract values from the URL path.

```dart
@TeleportRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  const UserPage({required this.userId});
  
  @Path('id')
  final String userId;
}

// Navigation
UserRoute(userId: '123').teleport(); // -> /user/123
```

### Query Parameters

Use `@Query()` to extract values from the query string.

```dart
@TeleportRoute(path: '/search')
class SearchPage extends StatelessWidget {
  const SearchPage({this.query, this.page});
  
  @Query('q')
  final String? query;
  
  @Query('page')
  final int? page; // Auto-parsed to int
}

// Navigation
SearchRoute(query: 'flutter', page: 2).teleport(); // -> /search?q=flutter&page=2
```

### Extra (Complex Objects)

For non-serializable objects (like models), they are passed via memory.

```dart
@TeleportRoute(path: '/profile')
class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.user});
  final User user; // Complex object, not in URL
}

// Navigation
ProfileRoute(user: currentUser).teleport();
```

> ⚠️ **Note**: Extra objects are **NOT** preserved during:
> - Browser Refresh
> - Direct URL entry (e.g. typing URL in address bar)
> - App kill/restart
> 
> For persistent data, use path/query params or state management services.

### Combined Example

```dart
@TeleportRoute(path: '/order/:orderId/detail')
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    required this.orderId,
    this.highlightItem,
    required this.orderData,
  });
  
  @Path('orderId')
  final String orderId;
  
  @Query('highlight')
  final String? highlightItem;
  
  final Order orderData; // Extra (passed via memory)
}

// Navigation
OrderDetailRoute(
  orderId: 'ORD-123',
  highlightItem: 'item-5',
  orderData: order,
).teleport();
// URL: /order/ORD-123/detail?highlight=item-5
// orderData passed via memory
```

---

## 🛡️ Guards & Redirects

### Route-Level Redirect

Protect specific routes. The `redirect` parameter accepts a `TeleportRedirect<T>` class.

```dart
// 1. Define the guard
class AuthGuard extends TeleportRedirect<ProtectedRoute> {
  @override
  FutureOr<TeleportRouteData?> handle(BuildContext context, ProtectedRoute route) {
    // Access the typed route object!
    if (!AuthService.instance.isLoggedIn) {
      return const LoginRoute(); // Redirect to login
    }
    return null; // Proceed (allow access)
  }
}

// 2. Apply to route
@TeleportRoute(path: '/protected', redirect: AuthGuard)
class ProtectedPage extends StatelessWidget { ... }
```

### Global Redirect

For app-wide rules (e.g., onboarding check, maintenance mode).

```dart
final router = TeleportRouter(
  routes: teleportRoutes,
  redirect: (context, state) {
    // state.fullPath is the target URL
    if (needsOnboarding && state.fullPath != '/onboarding') {
      return OnboardingRoute();
    }
    if (isLoggedIn && state.fullPath == '/login') {
      return HomeRoute(); // Already logged in, skip login
    }
    return null; // Allow
  },
);
```

### Reactive Routing (refreshListenable)

**This is how you make guards respond to state changes (e.g., login/logout).**

Without `refreshListenable`, the router doesn't know when to re-evaluate guards. After login, you'd be stuck on the login page even if the guard logic allows access.

```dart
// 1. Create a listenable auth service
class AuthService extends ChangeNotifier {
  static final instance = AuthService();
  
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners(); // 🔔 Signal the router!
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners(); // 🔔 Signal the router!
  }
}

// 2. Pass to TeleportRouter
final router = TeleportRouter(
  routes: teleportRoutes,
  refreshListenable: AuthService.instance, // <-- KEY!
  redirect: (context, state) {
    final loggedIn = AuthService.instance.isLoggedIn;
    final isOnLogin = state.fullPath == '/login';
    
    if (!loggedIn && !isOnLogin) return LoginRoute();
    if (loggedIn && isOnLogin) return HomeRoute();
    return null;
  },
);

// 3. Now when you call login()...
AuthService.instance.login();
// ...the router automatically re-evaluates and redirects!
```

**How it works:**
1. User navigates to `/protected`.
2. Guard runs, `isLoggedIn` is `false` → redirect to `/login`.
3. User logs in → `AuthService.login()` calls `notifyListeners()`.
4. `TeleportRouter` (listening to `refreshListenable`) re-runs the redirect logic.
5. Now `isLoggedIn` is `true` → user is allowed through (or redirected to home if on login page).

---

## 🔄 Route Lifecycle

### OnExit Guard

Intercept back navigation (e.g., unsaved changes confirmation).

```dart
// 1. Define the exit guard
class UnsavedChangesGuard extends TeleportOnExit<EditorRoute> {
  @override
  FutureOr<bool> onExit(BuildContext context, EditorRoute route) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('Discard changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Discard')),
        ],
      ),
    );
    return shouldExit ?? false; // true = allow exit, false = block
  }
}

// 2. Apply to route
@TeleportRoute(path: '/edit', onExit: UnsavedChangesGuard)
class EditorPage extends StatelessWidget { ... }
```

---

## 🔗 Deep Linking

TeleportRouter fully supports deep linking out of the box. All path and query parameters are automatically parsed.

**How it works:**
1. Define your route with path parameters: `@TeleportRoute(path: '/product/:id')`.
2. When a deep link like `yourapp://product/123?ref=email` is opened:
   - `id` is extracted as `'123'`.
   - `ref` is extracted as `'email'`.
3. Your page receives fully typed parameters.

**Example:**
```dart
@TeleportRoute(path: '/product/:productId')
class ProductPage extends StatelessWidget {
  const ProductPage({required this.productId, this.referrer});
  
  @Path('productId')
  final String productId;
  
  @Query('ref')
  final String? referrer;
}
```

**Deep link URL:** `https://example.com/product/abc123?ref=instagram`

**Platform Setup:**
- iOS: Configure `Associated Domains` in Xcode.
- Android: Add `intent-filter` to `AndroidManifest.xml`.
- Web: Works automatically.

See [go_router deep linking guide](https://pub.dev/documentation/go_router/latest/topics/Deep%20linking-topic.html) for platform-specific setup (TeleportRouter uses go_router internally).

---

## 🎨 Page Transitions

### Built-in Transitions

```dart
@TeleportRoute(
  path: '/details',
  transition: TeleportSlideTransition(), // TeleportSlideTransition, TeleportFadeTransition, etc.
  transitionDuration: 300,        // milliseconds
  reverseTransitionDuration: 200, // milliseconds (optional)
)
class DetailsPage extends StatelessWidget { ... }
```

**Available transitions:**
| Transition | Description |
|------------|-------------|
| `TeleportSlideTransition` | Slide from right |
| `TeleportFadeTransition` | Fade in/out |
| `TeleportScaleTransition` | Scale up/down |
| `TeleportNoTransition` | No animation |
| `TeleportCupertinoPageTransition` | iOS-style slide |

### Custom Transitions

Implement `TeleportTransitionsBuilder`:

```dart
class MyCustomTransition extends TeleportTransitionsBuilder {
  const MyCustomTransition();
  
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }
}

// Apply globally
final router = TeleportRouter(
  routes: teleportRoutes,
  defaultTransition: MyCustomTransition(),
);

// Or per-route (via annotation - requires custom setup)
```

### Swipe Back

Enable full-screen swipe-to-go-back gesture.

```dart
// Global default
final router = TeleportRouter(
  routes: teleportRoutes,
  defaultPageType: TeleportPageType.swipeBack,
);
```

---

## 📄 Page Configuration

The `@TeleportRoute` annotation supports rich page configuration options for dialogs, modals, transparency, and more.

### Page Type (TeleportPageType)

Control how the page is rendered:

```dart
@TeleportRoute(
  path: '/settings',
  type: TeleportPageType.swipeBack, // Use swipeBack page
)
class SettingsPage extends StatelessWidget { ... }
```

| Type | Description |
|------|-------------|
| `TeleportPageType.defaultType` | The default page type (replaces 'custom'). |
| `TeleportPageType.swipeBack` | Full-screen swipe-to-dismiss gesture. |

### Dialog & Modal Options

Create fullscreen dialogs (iOS modal sheets):

```dart
@TeleportRoute(
  path: '/create-post',
  fullscreenDialog: true, // Shows close button instead of back arrow on iOS
)
class CreatePostPage extends StatelessWidget { ... }
```

### Transparent Pages

Create transparent overlays, bottom sheets, or custom modals:

```dart
@TeleportRoute(
  path: '/overlay',
  opaque: false,                          // Page is transparent
  barrierColor: Color(0x80000000),         // Semi-transparent black barrier
  barrierDismissible: true,                // Tap barrier to close
  barrierLabel: 'Dismiss overlay',         // Accessibility label
)
class OverlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Text('Bottom Sheet Content'),
      ),
    );
  }
}
```

### Full @TeleportRoute Reference

All available `@TeleportRoute` parameters:

```dart
@TeleportRoute(
  // === Core ===
  path: '/user/:id',              // URL path pattern
  isInitial: false,               // Mark as initial route
  parentNavigatorKey: SomeNavKey, // Nest under a shell
  
  // === Guards ===
  redirect: AuthGuard,            // Redirect logic (TeleportRedirect<T>)
  onExit: UnsavedChangesGuard,    // Exit interception (TeleportOnExit<T>)
  
  // === Page Type ===
  type: TeleportPageType.defaultType,          // defaultType, swipeBack
  pageBuilder: MyCustomPage,      // Custom Page factory (overrides type)
  
  // === Transitions ===
  transition: TeleportSlideTransition(),        // Custom transition builder
  transitionDuration: Duration(milliseconds: 300),
  reverseTransitionDuration: Duration(milliseconds: 300),
  
  // === Dialog/Modal ===
  fullscreenDialog: false,        // iOS modal style (close button)
  opaque: true,                   // false = transparent page
  barrierDismissible: false,      // Tap outside to dismiss
  barrierColor: null,             // Barrier color (e.g. Color(0x80000000))
  barrierLabel: null,             // Accessibility label for barrier
  
  // === State ===
  maintainState: true,            // Keep state when inactive
)
class MyPage extends StatelessWidget { ... }
```

### Full @TeleportShellRoute Reference

`@TeleportShellRoute` supports page configuration plus shell-specific options:

```dart
@TeleportShellRoute(
  // === Core ===
  navigatorKey: MainNavKey,           // Required: Shell identifier
  parentNavigatorKey: RootNavKey,     // Optional: Nest shells
  isIndexedStack: true,               // Use StatefulShellRoute (preserves tab state)
  branchKeys: [HomeNavKey, ProfileNavKey], // Branch identifiers for IndexedStack
  
  // === Observers ===
  observers: [MyNavigatorObserver, AnalyticsObserver], // NavigatorObservers for this shell
  
  // === Page Configuration (same as TeleportRoute) ===
  type: TeleportPageType.swipeBack,
  fullscreenDialog: false,
  opaque: true,
  barrierDismissible: false,
  barrierColor: null,
  barrierLabel: null,
  maintainState: true,
  pageBuilder: MyShellPageBuilder,    // Custom Page factory
)
class MainShell extends StatelessWidget { ... }
```

**Observer Example:**

```dart
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    analytics.logPageView(route.settings.name);
  }
}

@TeleportShellRoute(
  navigatorKey: MainNavKey,
  observers: [AnalyticsObserver], // Attach to shell's navigator
)
class MainShell extends StatelessWidget { ... }
```

---

## ⚙️ Configuration

### TeleportRouter Options

```dart
TeleportRouter(
  routes: teleportRoutes,
  
  // Initial location (auto-detected from isInitial if not set)
  initialLocation: '/home',
  
  // Global redirect
  redirect: (context, state) => null,
  
  // Reactive routing trigger
  refreshListenable: authNotifier,
  
  // Error page
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  
  // Debug logging
  debugLogDiagnostics: true,
  
  // Transition defaults
  defaultTransition: TeleportSlideTransition(),
  defaultTransitionDuration: Duration(milliseconds: 300),
  defaultReverseTransitionDuration: Duration(milliseconds: 200),
  
  // Page type: auto, material, cupertino, swipeBack
  defaultPageType: TeleportPageType.auto,
  
  // Custom navigator key (must be a specific key instance)
  navigatorKey: const RootNavKey(),
  
  // Restoration for state persistence
  restorationScopeId: 'app_router',
  
  // Redirect limit to prevent infinite loops
  redirectLimit: 5,
);
```

### build.yaml Options

Customize generator output:

```yaml
targets:
  $default:
    builders:
      teleport_router_generator:
        options:
          output: lib/routes/app_routes.dart # Custom output path
```

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
