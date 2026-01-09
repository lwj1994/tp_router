import 'package:flutter/widgets.dart';
import 'navi_key.dart';
import 'route_observer.dart';

/// Global registry for navigator keys and observers.
///
/// This registry manages [GlobalKey<NavigatorState>] instances and [TpRouteObserver]
/// for named navigators in your application. It provides a centralized way to access
/// navigators and their observers by their [TpNavKey].
///
/// ## How it works
///
/// The registry stores a mapping from [TpNavKey] to [GlobalKey<NavigatorState>]
/// and [TpRouteObserver]. When you define a [TpNavKey] and access its [globalKey]
/// or [observer] property, the key/observer is automatically registered here.
///
/// ## Usage
///
/// Typically you don't interact with this registry directly. Instead:
///
/// 1. Define your navigator keys:
/// ```dart
/// class MainDashBoradNavKey extends TpNavKey {
///   const MainDashBoradNavKey() : super('dashboard');
/// }
/// ```
///
/// 2. Access the GlobalKey via the TpNavKey:
/// ```dart
/// // Preferred way - use TpNavKey.globalKey
/// final key = const MainDashBoradNavKey().globalKey;
///
/// // Or via registry (less common)
/// final key = TpNavigatorKeyRegistry.getOrCreate(const MainDashBoradNavKey());
/// ```
///
/// 3. Access the observer for route stack manipulation:
/// ```dart
/// final observer = TpNavigatorKeyRegistry.getOrCreateObserver(const MainDashBoradNavKey());
/// ```
class TpNavigatorKeyRegistry {
  TpNavigatorKeyRegistry._();

  static TpNavKey _rootKey = TpNavKey.value("tp_router_root");

  /// The global root navigator key.
  static TpNavKey get rootKey => _rootKey;

  /// Update the global root navigator key.
  static set rootKey(TpNavKey value) => _rootKey = value;

  /// Internal storage for navigator keys.
  static final Map<TpNavKey, GlobalKey<NavigatorState>> _keys = {};

  /// Internal storage for observers.
  static final Map<TpNavKey, TpRouteObserver> _observers = {};

  /// Get or create a navigator key for the given [TpNavKey].
  static GlobalKey<NavigatorState> getOrCreate(TpNavKey naviKey) {
    return _keys.putIfAbsent(
      naviKey,
      () => GlobalKey<NavigatorState>(debugLabel: naviKey.toString()),
    );
  }

  /// Get or create a TpRouteObserver for the given [TpNavKey].
  ///
  /// This allows each navigation branch to have its own observer
  /// for route stack manipulation (e.g., removeRoute, popUntil).
  static TpRouteObserver getOrCreateObserver(TpNavKey naviKey) {
    return _observers.putIfAbsent(naviKey, () => TpRouteObserver());
  }

  /// Get a navigator key if it exists.
  static GlobalKey<NavigatorState>? get(TpNavKey naviKey) => _keys[naviKey];

  /// Get an observer if it exists.
  static TpRouteObserver? getObserver(TpNavKey naviKey) => _observers[naviKey];

  /// Get all registered navigator keys.
  static Map<TpNavKey, GlobalKey<NavigatorState>> get all =>
      Map.unmodifiable(_keys);

  /// Get all registered observers.
  static Map<TpNavKey, TpRouteObserver> get allObservers =>
      Map.unmodifiable(_observers);

  /// Clear all registered keys and observers.
  ///
  /// **Warning**: This is mainly for testing purposes.
  static void clear() {
    _keys.clear();
    _observers.clear();
  }
}
