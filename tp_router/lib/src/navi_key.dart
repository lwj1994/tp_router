import 'package:flutter/widgets.dart';
import 'navigator_key_registry.dart';
import 'route.dart';
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
/// class DashboardNavKey extends TpNavKey {
///   const DashboardNavKey() : super('dashboard');
/// }
///
/// // 2. Use in shell route annotation
/// @TpShellRoute(navigatorKey: MainNavKey, isIndexedStack: true)
/// class MainShellPage extends StatelessWidget { ... }
///
/// // 3. Use in child route annotation
/// @TpRoute(path: '/', parentNavigatorKey: MainNavKey, branchIndex: 0)
/// class HomePage extends StatelessWidget { ... }
/// ```
///
/// ## Runtime Usage
///
/// Use navigator keys for targeted navigation operations:
///
/// ```dart
/// // Navigate within a specific navigator
/// SomeRoute().tp(navigatorKey: const DashboardNavKey());
///
/// // Pop from a specific navigator
/// TpRouter.instance.pop(navigatorKey: const DashboardNavKey());
///
/// // Get the GlobalKey for a navigator
/// final key = const MainNavKey().globalKey;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpNavKey && key == other.key && branch == other.branch;

  @override
  int get hashCode => Object.hash(key, branch);

  @override
  String toString() =>
      branch != null ? 'TpNavKey($key, branch: $branch)' : 'TpNavKey($key)';

  /// Navigate to a route using this navigator key.
  ///
  /// This is a shortcut for [TpRouter.tp] with `navigatorKey: this`.
  Future<T?> tp<T extends Object?>(
    TpRouteData route, {
    bool isReplace = false,
    bool isClearHistory = false,
  }) {
    return TpRouter.instance.tp<T>(
      route,
      navigatorKey: this,
      isReplace: isReplace,
      isClearHistory: isClearHistory,
    );
  }

  /// Pop the current route from this navigator.
  ///
  /// This is a shortcut for [TpRouter.pop] with `navigatorKey: this`.
  void pop<T extends Object?>([T? result]) {
    TpRouter.instance.pop<T>(navigatorKey: this, result: result);
  }

  /// Pop routes in this navigator until the predicate is satisfied.
  ///
  /// This is a shortcut for [TpRouter.popUntil] with `navigatorKey: this`.
  void popUntil(
      bool Function(Route<dynamic> route, TpRouteData? data) predicate) {
    TpRouter.instance.popUntil(predicate, navigatorKey: this);
  }

  /// Pop until the first route in the stack.
  void popToInitial() {
    TpRouter.instance.popToInitial(navigatorKey: this);
  }

  /// Pop until the specified route is found.
  void popTo(TpRouteData route) {
    TpRouter.instance.popTo(route, navigatorKey: this);
  }

  /// Remove a route from this navigator.
  ///
  /// This is a shortcut for [TpRouter.removeRoute] with `navigatorKey: this`.
  bool removeRoute(TpRouteData route) {
    return TpRouter.instance.removeRoute(
      route,
      navigatorKey: this,
    );
  }

  /// Remove all routes that match the given predicate from this navigator.
  ///
  /// This is a shortcut for [TpRouter.removeWhere] with `navigatorKey: this`.
  int removeWhere(bool Function(TpRouteData data) predicate) {
    return TpRouter.instance.removeWhere(
      predicate,
      navigatorKey: this,
    );
  }

  /// Check if this navigator can pop.
  ///
  /// This is a shortcut for [TpRouter.canPop] with `navigatorKey: this`.
  bool get canPop => TpRouter.instance.canPop(navigatorKey: this);

  /// Get the current location in this navigator.
  ///
  /// This is a shortcut for [TpRouter.location] with `navigatorKey: this`.
  TpRouteData get location => TpRouter.instance.location(navigatorKey: this);
}

/// Private implementation for factory constructor.
class _SimpleTpNavKey extends TpNavKey {
  const _SimpleTpNavKey(super.key, {super.branch});
}
