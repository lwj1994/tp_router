import 'package:flutter/widgets.dart';

/// Global registry for navigator keys.
///
/// This allows accessing navigators by their string key for operations
/// like removeRoute with specific navigators.
///
/// Usage in generated code:
/// ```dart
/// // In generated route file:
/// class DashboardShellRoute {
///   static final navigatorGlobalKey =
///     TpNavigatorKeyRegistry.getOrCreate('dashboard');
/// }
/// ```
///
/// Usage in application code:
/// ```dart
/// final key = TpNavigatorKeyRegistry.get('dashboard');
///
/// // For StatefulShellRoute branches:
/// final branchKey = TpNavigatorKeyRegistry.getBranch('main', 0);
/// ```
class TpNavigatorKeyRegistry {
  TpNavigatorKeyRegistry._();

  static final Map<String, GlobalKey<NavigatorState>> _keys = {};

  /// Get or create a navigator key by name.
  ///
  /// If the key already exists, returns the existing one.
  /// Otherwise, creates a new GlobalKey and registers it.
  static GlobalKey<NavigatorState> getOrCreate(String name) {
    return _keys.putIfAbsent(
      name,
      () => GlobalKey<NavigatorState>(debugLabel: name),
    );
  }

  /// Get a navigator key by name.
  ///
  /// Returns null if not found.
  static GlobalKey<NavigatorState>? get(String name) => _keys[name];

  /// Get a branch navigator key by shell key and branch index.
  ///
  /// This is a convenience method for accessing StatefulShellRoute branches.
  ///
  /// Example:
  /// ```dart
  /// // Get branch 0 of 'main' shell
  /// final key = TpNavigatorKeyRegistry.getBranch('main', 0);
  /// ```
  static GlobalKey<NavigatorState>? getBranch(
      String shellKey, int branchIndex) {
    return _keys['${shellKey}_branch_$branchIndex'];
  }

  /// Get all registered navigator keys.
  static Map<String, GlobalKey<NavigatorState>> get all =>
      Map.unmodifiable(_keys);

  /// Clear all registered keys.
  ///
  /// This is mainly for testing purposes.
  static void clear() => _keys.clear();
}
