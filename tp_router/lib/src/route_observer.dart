import 'package:flutter/widgets.dart';
import 'route.dart';

/// Navigator observer that tracks route history for stack manipulation.
///
/// This observer maintains a mapping of route names to Route instances,
/// allowing the delete() method to remove specific routes from the stack.
class TpRouteObserver extends NavigatorObserver {
  /// Map of route name to Route instances (supports multiple instances)
  final Map<String, List<Route>> _routesByName = {};

  /// All routes in order (bottom to top)
  final List<Route> _allRoutes = [];

  /// Map of Route to TpRouteData for accessing route details
  /// This is populated by calling registerRouteBuilder
  final Map<String, TpRouteData Function()> _routeBuilders = {};

  /// Actual TpRouteData instances for each route
  final Map<Route, TpRouteData> _routeDataMap = {};

  /// Routes marked for removal when they become active.
  final Set<Route> _pendingRemovals = {};

  /// Mark a route to be removed automatically when it becomes active (is popped to).
  void markRouteForRemoval(Route route) {
    _pendingRemovals.add(route);
  }

  /// Check if a route should be tracked by this observer.
  ///
  /// Only tracks routes with names starting with 'tp_router_' prefix.
  bool _shouldTrackRoute(Route route) {
    final name = route.settings.name;
    return name != null && name.startsWith('tp_router_');
  }

  /// Register a route builder function for a specific route name.
  ///
  /// This is called automatically by generated code to enable
  /// Observer to reconstruct TpRouteData from Route instances.
  void registerRouteBuilder(String name, TpRouteData Function() builder) {
    _routeBuilders[name] = builder;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (_shouldTrackRoute(route)) {
      _allRoutes.add(route);
      _addRouteToMap(route);
      _tryExtractRouteData(route);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (_shouldTrackRoute(route)) {
      _allRoutes.remove(route);
      _removeRouteFromMap(route);
      _routeDataMap.remove(route);
    }
    _pendingRemovals.remove(route); // Cleanup if popped normally

    // If the route revealed (previousRoute) is marked for removal, pop it.
    if (previousRoute != null && _pendingRemovals.contains(previousRoute)) {
      _pendingRemovals.remove(previousRoute);
      // Schedule pop for next frame to avoid conflicting transitions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator?.pop();
      });
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (_shouldTrackRoute(route)) {
      _allRoutes.remove(route);
      _removeRouteFromMap(route);
      _routeDataMap.remove(route);
    }
    _pendingRemovals.remove(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute != null && _shouldTrackRoute(oldRoute)) {
      final index = _allRoutes.indexOf(oldRoute);
      if (index != -1 && newRoute != null && _shouldTrackRoute(newRoute)) {
        _allRoutes[index] = newRoute;
      }
      _removeRouteFromMap(oldRoute);
      _routeDataMap.remove(oldRoute);
      _pendingRemovals
          .remove(oldRoute); // Cleanup pending status for replaced route
    }
    if (newRoute != null && _shouldTrackRoute(newRoute)) {
      _addRouteToMap(newRoute);
      _tryExtractRouteData(newRoute);
    }
  }

  /// Find route by name (returns first match)
  Route? findRoute(String name) {
    final routes = _routesByName[name];
    return routes?.isNotEmpty == true ? routes!.first : null;
  }

  /// Find all routes matching the name
  List<Route> findAllRoutes(String name) {
    return _routesByName[name]?.toList() ?? [];
  }

  /// Get all routes in the stack
  List<Route> get allRoutes => List.unmodifiable(_allRoutes);

  /// Get TpRouteData for a specific route
  ///
  /// Returns the stored TpRouteData if available, otherwise tries to
  /// extract from route.settings.arguments as TpRouteData.
  TpRouteData? getRouteData(Route route) {
    // Try cached data first
    if (_routeDataMap.containsKey(route)) {
      return _routeDataMap[route];
    }

    // Try to extract from arguments
    final arguments = route.settings.arguments;
    if (arguments is TpRouteData) {
      _routeDataMap[route] = arguments;
      return arguments;
    }

    return null;
  }

  /// Get all route data entries
  Map<Route, TpRouteData> get allRouteData => Map.unmodifiable(_routeDataMap);

  void _addRouteToMap(Route route) {
    final name = route.settings.name;
    if (name != null) {
      _routesByName.putIfAbsent(name, () => []).add(route);
    }
  }

  void _removeRouteFromMap(Route route) {
    final name = route.settings.name;
    if (name != null) {
      _routesByName[name]?.remove(route);
      if (_routesByName[name]?.isEmpty == true) {
        _routesByName.remove(name);
      }
    }
  }

  /// Try to extract TpRouteData from route settings arguments
  void _tryExtractRouteData(Route route) {
    final arguments = route.settings.arguments;
    if (arguments is TpRouteData) {
      _routeDataMap[route] = arguments;
    }
  }

  /// Clear all tracked routes
  void clear() {
    _routesByName.clear();
    _allRoutes.clear();
    _routeDataMap.clear();
  }
}
