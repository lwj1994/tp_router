import 'package:flutter/widgets.dart';
import 'navigator_key_registry.dart';
import 'route.dart';
import 'route_observer.dart';
import 'tp_router.dart';

/// Abstract base class for type-safe navigator keys.
///
/// Extend this class to define your own navigator keys with compile-time safety.
/// This is the recommended approach for production apps as it provides:
/// - Compile-time type checking
/// - Easy refactoring
/// - Centralized key definitions
///
/// ## Usage in Annotations
///
/// Define your navigator key classes and use them in `@TpShellRoute` and
/// `@TpRoute` annotations:
///
/// ```dart
/// // 1. Define your navigator keys (e.g., in routes/nav_keys.dart)
/// class MainNavKey extends TpNavKey {
///   const MainNavKey() : super('main');
/// }
///
/// class MainDashBoradNavKey extends TpNavKey {
///   const MainDashBoradNavKey() : super('dashboard');
/// }
///
/// // 2. Use in shell route annotation
/// @TpShellRoute(navigatorKey: MainNavKey, isIndexedStack: true)
/// class MainShellPage extends StatelessWidget { ... }
///
///   // Use in child route annotation
///   @TpRoute(path: '/', parentNavigatorKey: MainHomeNavKey) // Use branch-specific keys
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
/// For quick inline usage without defining a custom class, use [TpNavKey.value]:
///
/// ```dart
/// TpNavKey.value('dashboard')
/// TpNavKey.value('main', branch: 0)
/// ```
///
/// Note: Using factory is less type-safe. Prefer custom classes for production.
abstract class TpNavKey {
  /// The string key used internally for registration.
  ///
  /// This key should be unique across your application.
  final String key;

  /// Optional branch index for StatefulShellRoute branches.
  ///
  /// Used internally to create separate GlobalKeys for each branch
  /// of an indexed stack navigation.
  final int? branch;

  /// Creates a TpNavKey with the given [key] and optional [branch].
  const TpNavKey(this.key, {this.branch});

  /// Factory constructor for quick inline usage.
  ///
  /// Use this when you don't need a custom class:
  /// ```dart
  /// TpNavKey.value('dashboard')
  /// TpNavKey.value('main', branch: 0)
  /// ```
  ///
  /// Note: For better type safety, prefer extending [TpNavKey] directly.
  // ignore: prefer_const_constructors_in_immutables
  factory TpNavKey.value(String key, {int? branch}) = _SimpleTpNavKey;

  /// Get the GlobalKey associated with this navigator key.
  ///
  /// Creates and registers the key if it doesn't exist yet.
  /// The key is stored in [TpNavigatorKeyRegistry] and reused
  /// across the application lifetime.
  GlobalKey<NavigatorState> get globalKey {
    return TpNavigatorKeyRegistry.getOrCreate(this);
  }

  /// Get the TpRouteObserver associated with this navigator key.
  ///
  /// Creates and registers the observer if it doesn't exist yet.
  /// Each navigator branch has its own observer for independent
  /// route stack manipulation (e.g., removeRoute, popUntil).
  TpRouteObserver get observer {
    return TpNavigatorKeyRegistry.getOrCreateObserver(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpNavKey && key == other.key && branch == other.branch;

  @override
  int get hashCode => Object.hash(key, branch);

  @override
  String toString() =>
      branch != null ? 'TpNavKey($key, branch: $branch)' : 'TpNavKey($key)';

  /// Pop the top route from this navigator.
  ///
  /// This is a shortcut for [TpRouter.pop] with `navigatorKey: this`.
  void pop<T extends Object?>([T? result]) {
    TpRouter.instance.pop(result: result, navigatorKey: this);
  }

  /// Check if this navigator can pop.
  bool get canPop => globalKey.currentState?.canPop() ?? false;

  /// Get the current location in this navigator.
  ///
  /// This is a shortcut for [TpRouter.location] with `navigatorKey: this`.
  TpRouteData get location => TpRouter.instance.location(navigatorKey: this);
}

/// Private implementation for factory constructor.
class _SimpleTpNavKey extends TpNavKey {
  const _SimpleTpNavKey(super.key, {super.branch});
}
