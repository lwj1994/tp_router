import 'package:flutter/widgets.dart';

/// Annotation to mark a widget class as a route.
///
/// This annotation is processed by the build_runner to
/// automatically generate route table entries.
///
/// Example:
/// ```dart
/// @TeleportRoute(path: '/home')
/// class HomePage extends StatelessWidget {
///   const HomePage({super.key});
///   // ...
/// }
///
/// // With custom transition:
/// @TeleportRoute(path: '/details', transitionsBuilder: TeleportFadeTransition())
/// class DetailsPage extends StatelessWidget { ... }
/// ```
/// Defines the type of page to use for a route.
enum TeleportPageType {
  /// The default page type.
  defaultType,

  /// Use SwipeBackWrapper (Left edge swipe to close).
  swipeBack,
}

class TeleportRoute {
  /// The URL path for this route.
  ///
  /// Example: '/home', '/user/:id', '/settings'
  ///
  /// If null or empty, it will be auto-generated from the class name.
  final String? path;

  /// Whether this route is the initial/default route.
  ///
  /// Only one route should be marked as initial.
  final bool isInitial;

  /// Custom transition builder for this route.
  ///
  /// Should be a const instance of a class that extends [TeleportTransitionsBuilder].
  /// Built-in options (from teleport_router): TeleportFadeTransition, TeleportSlideTransition, TeleportNoTransition.
  ///
  /// Example:
  /// ```dart
  /// @TeleportRoute(path: '/fade', transition: TeleportFadeTransition())
  /// class FadePage extends StatelessWidget { ... }
  /// ```
  final TeleportTransitionsBuilder? transition;

  /// Transition duration. Defaults to 300ms.
  final Duration transitionDuration;

  /// Reverse transition duration. Defaults to 300ms.
  final Duration reverseTransitionDuration;

  /// A class implementing `TeleportRedirect` (from teleport_router package) to handle redirection.
  ///
  /// Example:
  /// ```dart
  /// @TeleportRoute(path: '/protected', redirect: AuthRedirect)
  /// class ProtectedPage extends StatelessWidget { ... }
  /// ```
  final Type? redirect;

  /// Optional key of the parent shell.
  ///
  /// Specify a [TeleportNavKey] subclass type that this route belongs to.
  ///
  /// Example:
  /// ```dart
  /// @TeleportRoute(path: '/home', parentNavigatorKey: MainNavKey)
  /// class HomePage extends StatelessWidget { ... }
  /// ```
  final Type? parentNavigatorKey;

  /// Handle logic when route is exiting.
  ///
  /// Must be a implementation of `TeleportOnExit` (from teleport_router package).
  final Type? onExit;

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

  /// The specific type of page to construct.
  final TeleportPageType? type;

  /// Custom PageBuilder class type.
  ///
  /// If provided, this factory will be used to build the [Page], overriding
  /// any [transition] or default page settings.
  final Type? pageBuilder;

  /// Creates a [TeleportRoute] annotation.
  const TeleportRoute({
    this.path,
    this.isInitial = false,
    this.redirect,
    this.type,
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.parentNavigatorKey,
    this.onExit,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.pageBuilder,
  });
}

/// Abstract base class for custom page transitions.
///
/// Extend this class to create custom page transition animations.
/// Built-in implementations are provided in `teleport_router` package.
///
/// Example:
/// ```dart
/// class MySlideTransition extends TeleportTransitionsBuilder {
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
abstract class TeleportTransitionsBuilder {
  const TeleportTransitionsBuilder();

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
/// `navigatorKey` parameter on `@TeleportRoute`.
///
/// ## Mode 1: Regular ShellRoute (`isIndexedStack: false`)
///
/// For simple shell layouts where child routes share a common wrapper.
/// The shell widget receives a `child` parameter.
///
/// ```dart
/// @TeleportShellRoute(navigatorKey: MainNavKey)
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
/// @TeleportRoute(path: '/home', parentNavigatorKey: MainNavKey)
/// class HomePage extends StatelessWidget { ... }
/// ```
///
/// ## Mode 2: StatefulShellRoute with IndexedStack (`isIndexedStack: true`)
///
/// For bottom navigation bars where each tab maintains its own navigation
/// state. The shell widget receives a `navigationShell` parameter of type
/// [TeleportStatefulNavigationShell]. Use `parentNavigatorKey` with branch-specific
/// Keys (defined in `branchKeys` of the shell) to place routes in specific branches.
///
/// ```dart
/// @TeleportShellRoute(
///   navigatorKey: MainNavKey,
///   isIndexedStack: true,
///   branchKeys: [HomeNavKey, SettingsNavKey]
/// )
/// class MainShell extends StatelessWidget {
///   final TeleportStatefulNavigationShell navigationShell;
///   const MainShell({required this.navigationShell, super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: navigationShell,
///       bottomNavigationBar: BottomNavigationBar(
///         currentIndex: navigationShell.currentIndex,
///         onTap: (index) => navigationShell.teleport(index),
///         items: [...],
///       ),
///     );
///   }
/// }
///
/// @TeleportRoute(path: '/home', parentNavigatorKey: HomeNavKey)
/// class HomePage extends StatelessWidget { ... }
///
/// @TeleportRoute(path: '/settings', parentNavigatorKey: SettingsNavKey)
/// class SettingsPage extends StatelessWidget { ... }
/// ```
class TeleportShellRoute {
  /// The specific type of page to construct.
  final TeleportPageType? type;

  /// The navigator key class for this shell route.
  ///
  /// Must be a subclass of [TeleportNavKey]. Child routes with matching
  /// `parentNavigatorKey` in their `@TeleportRoute` annotation will be
  /// automatically grouped under this shell.
  ///
  /// Example:
  /// ```dart
  /// class MainNavKey extends TeleportNavKey {
  ///   const MainNavKey() : super('main');
  /// }
  ///
  /// @TeleportShellRoute(navigatorKey: MainNavKey)
  /// class MainShell extends StatelessWidget { ... }
  /// ```
  final Type navigatorKey;

  /// Base path for this shell's child routes (optional).
  ///
  /// When specified, child routes with relative paths (not starting with '/')
  /// will be prefixed with this base path.
  ///
  /// Example:
  /// ```dart
  /// @TeleportShellRoute(navigatorKey: DashboardNavKey, basePath: '/dashboard')
  /// class DashboardShell extends StatelessWidget { ... }
  ///
  /// @TeleportRoute(path: 'overview', parentNavigatorKey: DashboardNavKey)
  /// // Resolved to: /dashboard/overview
  /// class OverviewPage extends StatelessWidget { ... }
  /// ```
  final String? basePath;

  /// Optional key of the parent shell.
  ///
  /// If provided, this shell route will be nested inside the specified parent
  /// shell route. Must be a subclass of [TeleportNavKey].
  final Type? parentNavigatorKey;

  /// Whether to use StatefulShellRoute.indexedStack.
  ///
  /// When `true`, the shell uses [TeleportStatefulNavigationShell] which preserves
  /// navigation state for each branch (tab). When `false`, it uses a simple
  /// [ShellRoute] with a `child` widget parameter.
  final bool isIndexedStack;

  /// List of [NavigatorObserver] types to add to this shell's Navigator.
  ///
  /// The generator will instantiate these classes using their default constructor.
  /// Example:
  /// ```dart
  /// @TeleportShellRoute(
  ///   navigatorKey: MainNavKey,
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

  /// Custom PageBuilder class type.
  ///
  /// If provided, this factory will be used to build the [Page], overriding
  /// any [transition] or default page settings.
  final Type? pageBuilder;

  /// List of navigator keys for each branch (for IndexedStack).
  ///
  /// If provided, child routes can reference these keys as their [parentNavigatorKey]
  /// to be automatically placed in the corresponding branch.
  ///
  /// Example:
  /// ```dart
  /// @TeleportShellRoute(
  ///   navigatorKey: MainNavKey,
  ///   branchKeys: [HomeNavKey, SettingsNavKey],
  /// )
  /// class MainShell ...
  /// ```
  final List<Type>? branchKeys;

  /// Creates a [TeleportShellRoute] annotation.
  const TeleportShellRoute({
    required this.navigatorKey,
    this.parentNavigatorKey,
    this.basePath,
    this.isIndexedStack = false,
    this.observers,
    this.branchKeys,
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.type,
    this.pageBuilder,
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
