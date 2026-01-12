import 'package:flutter/widgets.dart';
import 'navigator_key_registry.dart';
import 'route.dart';
import 'route_observer.dart';
import 'teleport_router.dart';

/// Abstract base class for type-safe navigator keys.
///
/// A [TeleportNavKey] serves as a strict identifier for a specific `Navigator`.
/// Unlike a raw string or [GlobalKey], it encapsulates:
/// 1. The [GlobalKey<NavigatorState>] for controlling navigation.
/// 2. The [TeleportRouteObserver] for tracking the route stack of that navigator.
///
/// Extend this class to define your own navigator keys with compile-time safety.
/// This is the recommended approach for production apps as it provides:
/// - Compile-time type checking
/// - Easy refactoring
/// - Centralized key definitions
/// - **Automatic Observer Injection**: When used in shell routes, it automatically injects
///   the associated observer into the navigator.
///
/// **Important Check**:
/// A [TeleportNavKey] instance corresponds to a unique `GlobalKey`. Do **not** use the same
/// key instance (or logically equal instances) for multiple `ShellRoute`s or `Navigator`s
/// simultaneously. Doing so will cause a "Duplicate GlobalKey" error in Flutter.
///
/// ## Usage in Annotations
///
/// Define your navigator key classes and use them in `@TeleportShellRoute` and
/// `@TeleportRoute` annotations:
///
/// ```dart
/// // 1. Define your navigator keys (e.g., in routes/nav_keys.dart)
/// class MainNavKey extends TeleportNavKey {
///   const MainNavKey() : super('main');
/// }
///
/// class MainDashBoradNavKey extends TeleportNavKey {
///   const MainDashBoradNavKey() : super('dashboard');
/// }
///
/// // 2. Use in shell route annotation
/// @TeleportShellRoute(navigatorKey: MainNavKey, isIndexedStack: true)
/// class MainShellPage extends StatelessWidget { ... }
///
///   // Use in child route annotation
///   @TeleportRoute(path: '/', parentNavigatorKey: MainHomeNavKey) // Use branch-specific keys
///   class HomePage extends StatelessWidget { ... }
///   ```
///
/// ## Runtime Usage
///
/// Use navigator keys for targeted navigation operations (specifically pop):
///
/// ```dart
/// // Pop from a specific navigator
/// const MainDashBoradNavKey().pop();
///
/// // Check ability to pop
/// bool canPop = const MainNavKey().canPop;
/// ```
///
/// ## Factory Constructor
///
/// For quick inline usage without defining a custom class, use [TeleportNavKey.value]:
///
/// ```dart
/// TeleportNavKey.value('dashboard')
/// TeleportNavKey.value('main', branch: 0)
/// ```
///
/// Note: Using factory is less type-safe. Prefer custom classes for production.
abstract class TeleportNavKey {
  /// The string key used internally for registration.
  ///
  /// This key should be unique across your application.
  final String key;

  /// Optional branch index for StatefulShellRoute branches.
  ///
  /// Used internally to create separate GlobalKeys for each branch
  /// of an indexed stack navigation.
  final int? branch;

  /// Creates a TeleportNavKey with the given [key] and optional [branch].
  const TeleportNavKey(this.key, {this.branch});

  /// Factory constructor for quick inline usage.
  ///
  /// Use this when you don't need a custom class:
  /// ```dart
  /// TeleportNavKey.value('dashboard')
  /// TeleportNavKey.value('main', branch: 0)
  /// ```
  ///
  /// Note: For better type safety, prefer extending [TeleportNavKey] directly.
  // ignore: prefer_const_constructors_in_immutables
  factory TeleportNavKey.value(String key, {int? branch}) =
      _SimpleTeleportNavKey;

  /// Get the GlobalKey associated with this navigator key.
  ///
  /// Creates and registers the key if it doesn't exist yet.
  /// The key is stored in [TeleportNavigatorKeyRegistry] and reused
  /// across the application lifetime.
  GlobalKey<NavigatorState> get globalKey {
    return TeleportNavigatorKeyRegistry.getOrCreate(this);
  }

  /// Get the TeleportRouteObserver associated with this navigator key.
  ///
  /// Creates and registers the observer if it doesn't exist yet.
  /// Each navigator branch has its own observer for independent
  /// route stack manipulation (e.g., removeRoute, popUntil).
  TeleportRouteObserver get observer {
    return TeleportNavigatorKeyRegistry.getOrCreateObserver(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeleportNavKey && key == other.key && branch == other.branch;

  @override
  int get hashCode => Object.hash(key, branch);

  @override
  String toString() => branch != null
      ? 'TeleportNavKey($key, branch: $branch)'
      : 'TeleportNavKey($key)';

  /// Pop the top route from this navigator.
  ///
  /// This is a shortcut for [TeleportRouter.pop] with `navigatorKey: this`.
  void pop<T extends Object?>([T? result]) {
    TeleportRouter.instance.pop<T>(result: result);
  }

  /// Check if this navigator can pop.
  bool get canPop => globalKey.currentState?.canPop() ?? false;

  /// Get the current location in this navigator.
  ///
  /// This is a shortcut for [TeleportRouter.getCurrentRoute] with `navigatorKey: this`.
  ///
  /// **Note**: [TeleportRouter] must be initialized before calling this.
  TeleportRouteData get currentRoute =>
      TeleportRouter.instance.currentRoute(navigatorKey: this);
}

/// Private implementation for factory constructor.
class _SimpleTeleportNavKey extends TeleportNavKey {
  const _SimpleTeleportNavKey(super.key, {super.branch});
}
