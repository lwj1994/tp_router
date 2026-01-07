import 'package:flutter/widgets.dart';

/// Annotation to mark a widget class as a route.
///
/// This annotation is processed by the build_runner to
/// automatically generate route table entries.
///
/// Example:
/// ```dart
/// @TpRoute(path: '/home')
/// class HomePage extends StatelessWidget {
///   const HomePage({super.key});
///   // ...
/// }
///
/// // With custom transition:
/// @TpRoute(path: '/details', transitionsBuilder: TpFadeTransition())
/// class DetailsPage extends StatelessWidget { ... }
/// ```
  class TpRoute {
  /// The URL path for this route.
  ///
  /// Example: '/home', '/user/:id', '/settings'
  /// The URL path for this route.
  ///
  /// Example: '/home', '/user/:id', '/settings'
  ///
  /// If null or empty, it will be auto-generated from the class name.
  final String? path;

  /// Optional name for the route.
  ///
  /// If not provided, the class name will be used.
  final String? name;

  /// Whether this route is the initial/default route.
  ///
  /// Only one route should be marked as initial.
  final bool isInitial;

  /// Custom transition builder for this route.
  ///
  /// Should be a const instance of a class that extends [TpTransitionsBuilder].
  /// Built-in options (from tp_router): TpFadeTransition, TpSlideTransition, TpNoTransition.
  ///
  /// Example:
  /// ```dart
  /// @TpRoute(path: '/fade', transition: TpFadeTransition())
  /// class FadePage extends StatelessWidget { ... }
  /// ```
  final TpTransitionsBuilder? transition;

  /// Transition duration. Defaults to 300ms.
  final Duration transitionDuration;

  /// Reverse transition duration. Defaults to 300ms.
  final Duration reverseTransitionDuration;

  /// A top-level function or static method to handle redirection.
  ///
  /// Signature: `FutureOr<TpRouteData?> redirect(BuildContext context, TpRouteData state)`
  ///
  /// Example:
  /// ```dart
  /// @TpRoute(path: '/protected', redirect: authRedirect)
  /// class ProtectedPage extends StatelessWidget { ... }
  /// ```
  final dynamic redirect;

  /// Optional key of the parent shell.
  ///
  /// Specify the `navigatorKey` of the [TpShellRoute] that this route belongs to.
  ///
  /// Example:
  /// ```dart
  /// @TpRoute(path: '/home', parentNavigatorKey: 'main')
  /// class HomePage extends StatelessWidget { ... }
  /// ```
  final String? parentNavigatorKey;

  /// Branch index when used with a StatefulShellRoute (isIndexedStack: true).
  ///
  /// Routes with the same `parentNavigatorKey` but different `branchIndex` will be
  /// placed in separate branches. Routes with the same `branchIndex` will be
  /// in the same branch (as nested routes).
  ///
  /// Default is 0.
  final int branchIndex;

  /// Handle logic when route is exiting.
  ///
  /// Must be a top-level function or static method:
  /// `FutureOr<bool> Function(BuildContext, GoRouterState)`
  final Function? onExit;

  /// Whether this page is a fullscreen dialog (iOS modal style).
  final bool fullscreenDialog;

  /// Whether the page is opaque. Set to false for transparent dialogs.
  final bool opaque;

  /// Whether clicking the barrier dismisses the page.
  final bool barrierDismissible;

  /// The color of the barrier (background dimming).
  /// The color of the barrier (background dimming).
  ///
  /// Example: `Color(0x80000000)` (Black 50%)
  final Color? barrierColor;

  /// Semantic label for the barrier.
  final String? barrierLabel;

  /// Whether to maintain state when the route is inactive.
  final bool maintainState;

  /// Creates a [TpRoute] annotation.
  const TpRoute({
    this.path,
    this.name,
    this.isInitial = false,
    this.redirect,
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.parentNavigatorKey,
    this.branchIndex = 0,
    this.onExit,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
  });
}

/// Abstract base class for custom page transitions.
///
/// Extend this class to create custom page transition animations.
/// Built-in implementations are provided in `tp_router` package.
///
/// Example:
/// ```dart
/// class MySlideTransition extends TpTransitionsBuilder {
///   const MySlideTransition();
///
///   @override
///   Widget buildTransitions(
///     BuildContext context,
///     Animation<double> animation,
///     Animation<double> secondaryAnimation,
///     Widget child,
///   ) {
///     return SlideTransition(
///       position: Tween<Offset>(
///         begin: const Offset(1.0, 0.0),
///         end: Offset.zero,
///       ).animate(animation),
///       child: child,
///     );
///   }
/// }
/// ```
abstract class TpTransitionsBuilder {
  const TpTransitionsBuilder();

  /// Build the transition animation for the page.
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}

/// Annotation to mark a widget class as a shell route.
///
/// A shell route wraps other routes with a common UI (like a bottom navigation
/// bar or side drawer). Child routes are automatically associated via the
/// `navigatorKey` parameter on `@TpRoute`.
///
/// ## Mode 1: Regular ShellRoute (`isIndexedStack: false`)
///
/// For simple shell layouts where child routes share a common wrapper.
/// The shell widget receives a `child` parameter.
///
/// ```dart
/// @TpShellRoute(navigatorKey: 'main')
/// class MainShell extends StatelessWidget {
///   final Widget child;
///   const MainShell({required this.child, super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: child,
///       bottomNavigationBar: MyBottomNavBar(),
///     );
///   }
/// }
///
/// @TpRoute(path: '/home', navigatorKey: 'main')
/// class HomePage extends StatelessWidget { ... }
/// ```
///
/// ## Mode 2: StatefulShellRoute with IndexedStack (`isIndexedStack: true`)
///
/// For bottom navigation bars where each tab maintains its own navigation
/// state. The shell widget receives a `navigationShell` parameter of type
/// [TpStatefulNavigationShell]. Use `branchIndex` on child routes to specify
/// which branch they belong to.
///
/// ```dart
/// @TpShellRoute(navigatorKey: 'main', isIndexedStack: true)
/// class MainShell extends StatelessWidget {
///   final TpStatefulNavigationShell navigationShell;
///   const MainShell({required this.navigationShell, super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: navigationShell,
///       bottomNavigationBar: BottomNavigationBar(
///         currentIndex: navigationShell.currentIndex,
///         onTap: (index) => navigationShell.goBranch(index),
///         items: [...],
///       ),
///     );
///   }
/// }
///
/// @TpRoute(path: '/home', navigatorKey: 'main', branchIndex: 0)
/// class HomePage extends StatelessWidget { ... }
///
/// @TpRoute(path: '/settings', navigatorKey: 'main', branchIndex: 1)
/// class SettingsPage extends StatelessWidget { ... }
/// ```
class TpShellRoute {
  /// The key to identify this shell route.
  ///
  /// Child routes with matching `parentNavigatorKey` in their `@TpRoute` annotation
  /// will be automatically grouped under this shell.
  final String navigatorKey;

  /// Optional key of the parent shell.
  ///
  /// If provided, this shell route will be nested inside the specified parent
  /// shell route.
  final String? parentNavigatorKey;

  /// Branch index when used within a parent StatefulShellRoute.
  ///
  /// Default is 0.
  final int branchIndex;

  /// Whether to use StatefulShellRoute.indexedStack.
  ///
  /// When `true`, the shell uses [TpStatefulNavigationShell] which preserves
  /// navigation state for each branch (tab). When `false`, it uses a simple
  /// [ShellRoute] with a `child` widget parameter.
  final bool isIndexedStack;

  /// List of [NavigatorObserver] types to add to this shell's Navigator.
  ///
  /// The generator will instantiate these classes using their default constructor.
  /// Example:
  /// ```dart
  /// @TpShellRoute(
  ///   navigatorKey: 'main',
  ///   observers: [MyObserver, AnotherObserver],
  /// )
  /// ```
  final List<Type>? observers;

  /// Whether this page is a fullscreen dialog (iOS modal style).
  final bool fullscreenDialog;

  /// Whether the page is opaque. Set to false for transparent dialogs.
  final bool opaque;

  /// Whether clicking the barrier dismisses the page.
  final bool barrierDismissible;

  /// The color of the barrier (background dimming).
  ///
  /// Example: `Color(0x80000000)` (Black 50%)
  final Color? barrierColor;

  /// Semantic label for the barrier.
  final String? barrierLabel;

  /// Whether to maintain state when the route is inactive.
  final bool maintainState;

  /// Custom transition builder for this route.
  final TpTransitionsBuilder? transition;

  /// Transition duration. Defaults to 300ms.
  final Duration transitionDuration;

  /// Reverse transition duration. Defaults to 300ms.
  final Duration reverseTransitionDuration;

  /// Creates a [TpShellRoute] annotation.
  const TpShellRoute({
    required this.navigatorKey,
    this.parentNavigatorKey,
    this.branchIndex = 0,
    this.isIndexedStack = false,
    this.observers,
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.transition,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  });
}

/// Annotation to mark a parameter as coming from URL path.
class Path {
  /// Custom parameter name in the path.
  final String? name;

  /// Creates a [Path] annotation.
  const Path([this.name]);
}

/// Annotation to mark a parameter as coming from query string.
class Query {
  /// Custom parameter name in the query string.
  final String? name;

  /// Creates a [Query] annotation.
  const Query([this.name]);
}
