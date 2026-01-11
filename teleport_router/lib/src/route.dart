import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:teleport_router/src/teleport_router.dart';
import 'package:teleport_router_annotation/teleport_router_annotation.dart';
import 'navi_key.dart';
import 'page_factory.dart';

/// Configuration for TeleportRouter options.
///
/// These settings serve as global defaults for the application.
/// Individual routes can override these settings by providing their own values.
///
/// Priority: Route-specific setting > TeleportRouterConfig setting > System default
class TeleportRouterConfig {
  /// Default transition builder for all routes.
  /// Overridden by [TeleportRouteInfo.transition].
  final TeleportTransitionsBuilder? defaultTransition;

  /// Default transition duration.
  /// Overridden by [TeleportRouteInfo.transitionDuration].
  final Duration? defaultTransitionDuration;

  /// Default reverse transition duration.
  /// Overridden by [TeleportRouteInfo.reverseTransitionDuration].
  final Duration? defaultReverseTransitionDuration;

  const TeleportRouterConfig({
    this.defaultTransition,
    this.defaultTransitionDuration,
    this.defaultReverseTransitionDuration,
    this.defaultPageType,
    this.defaultPageBuilder,
  });

  /// Default page type (e.g. material, cupertino, transparent).
  /// Overridden by [TeleportRouteInfo.type].
  final TeleportPageType? defaultPageType;

  /// Default page factory for custom page construction.
  /// Overridden by [TeleportRouteInfo.pageBuilder].
  final TeleportPageFactory? defaultPageBuilder;
}

/// Base class for all route objects used in navigation.
///
/// This class serves two purposes:
/// 1. For navigation: Use generated route classes or [TeleportRouteData.fromPath]
/// 2. For reading current route: Use [TeleportRouteData.of(context)] or `context.teleportRouteData`
///
/// Example:
/// ```dart
/// // Navigation
/// context.teleportRouter.teleport(HomeRoute());
/// context.teleportRouter.teleport(TeleportRouteData.fromPath('/user/123'));
///
/// // Reading current route parameters
/// final data = context.teleportRouteData;
/// final userId = data.getInt('id');
/// ```
abstract class TeleportRouteData {
  /// The full path of the route including query parameters.
  String get fullPath;

  /// The URI of the current route.
  Uri get uri => Uri.parse(fullPath);

  /// Path parameters extracted from the URL.
  Map<String, String> get pathParams => const {};

  /// Query parameters from the URL.
  Map<String, String> get queryParams => const {};

  /// Extra data passed to the route.
  Object? get extra => null;

  /// Error associated with this route, if any.
  Object? get error => null;

  /// The page key used by GoRouter (useful for maintaining state).
  LocalKey? get pageKey => null;

  /// The name of the route (null if not named).
  String? get routeName;

  const TeleportRouteData();

  /// Creates a [TeleportRouteData] from a path string for navigation.
  ///
  /// Example:
  /// ```dart
  /// context.teleportRouter.teleport(TeleportRouteData.fromPath('/user/123'));
  /// context.teleportRouter.teleport(TeleportRouteData.fromPath('/home', extra: {'key': 'value'}));
  /// ```
  factory TeleportRouteData.fromPath(String path, {Object? extra = const {}}) {
    return _PathRoute(path, extra: extra);
  }

  factory TeleportRouteData.fromRoute(Route route) {
    // 1. Try to recover from arguments (TeleportRouter usually puts data there)
    final args = route.settings.arguments;
    if (args is TeleportRouteData) {
      return args;
    }

    // 2. Fallback: Parse from settings
    final name = route.settings.name ?? '';
    final uri = Uri.tryParse(name) ?? Uri();

    return _ContextRouteData(
      fullPath: name,
      routeName: name,
      pathParams: const {}, // Cannot recover path params from raw Route without matching
      queryParams: uri.queryParameters,
      extra: args, // Assuming extra is Map if generic
      pageKey: null,
    );
  }

  /// Gets the current route data from the given [context].
  ///
  /// Example:
  /// ```dart
  /// final data = TeleportRouteData.of(context);
  /// final userId = data.getInt('id');
  /// ```
  static TeleportRouteData of(BuildContext context) {
    return GoRouterStateData(GoRouterState.of(context));
  }

  /// Navigate to this route.
  ///
  /// [context]: Optional BuildContext for context-aware navigation.
  /// [clearHistory]: If true, clears navigation history (like `go`).
  /// [replacement]: If true, replaces the current route.
  /// [navigatorKey]: Targets a specific navigator by its [TeleportNavKey].
  ///
  /// **Note**: You cannot pass both [context] and [navigatorKey] at the same
  /// time. Use [context] for context-aware navigation within the current
  /// navigator, or use [navigatorKey] for navigating within a specific
  /// named navigator.
  ///
  /// Example:
  /// ```dart
  /// // Navigate with context (uses current navigator)
  /// UserRoute(id: 123).teleport(context);
  ///
  /// // Navigate to specific navigator (uses TeleportRouter.instance)
  /// DetailsRoute().teleport(null, navigatorKey: const DashboardNavKey());
  ///
  /// // Wait for result
  /// final result = await SelectRoute().teleport<String>(context);
  /// ```
  Future<T?> teleport<T extends Object?>({
    bool clearHistory = false,
    bool replacement = false,
  }) {
    return TeleportRouter.instance.teleport<T>(
      this,
      isReplace: replacement,
      isClearHistory: clearHistory,
    );
  }

  // ============ Parameter Access Methods ============

  /// Get a String parameter from path or query params.
  String? getString(String key, {String? defaultValue}) {
    return pathParams[key] ?? queryParams[key] ?? defaultValue;
  }

  /// Get a required String parameter.
  String getStringRequired(String key) {
    final value = getString(key);
    if (value == null) {
      throw ArgumentError('Missing required String parameter: $key');
    }
    return value;
  }

  /// Get an int parameter from path or query params.
  int? getInt(String key, {int? defaultValue}) {
    final raw = pathParams[key] ?? queryParams[key];
    if (raw == null) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }

  /// Get a required int parameter.
  int getIntRequired(String key) {
    final value = getInt(key);
    if (value == null) {
      throw ArgumentError('Missing required int parameter: $key');
    }
    return value;
  }

  /// Get a double parameter from path or query params.
  double? getDouble(String key, {double? defaultValue}) {
    final raw = pathParams[key] ?? queryParams[key];
    if (raw == null) return defaultValue;
    return double.tryParse(raw) ?? defaultValue;
  }

  /// Get a required double parameter.
  double getDoubleRequired(String key) {
    final value = getDouble(key);
    if (value == null) {
      throw ArgumentError('Missing required double parameter: $key');
    }
    return value;
  }

  /// Get a bool parameter from path or query params.
  bool? getBool(String key, {bool? defaultValue}) {
    final raw = pathParams[key] ?? queryParams[key];
    if (raw == null) return defaultValue;
    return _parseBool(raw) ?? defaultValue;
  }

  /// Get a required bool parameter.
  bool getBoolRequired(String key) {
    final value = getBool(key);
    if (value == null) {
      throw ArgumentError('Missing required bool parameter: $key');
    }
    return value;
  }

  /// Get a typed value from extra data by key.
  T? getExtra<T>(String key) {
    final e = extra;
    if (e is Map) {
      final value = e[key];
      if (value is T) {
        return value;
      }
    }
    return null;
  }

  /// Get the entire extra object as a typed value.
  T? getExtraAs<T>() {
    final e = extra;
    if (e is T) {
      return e;
    }
    return null;
  }

  /// Access any parameter by key (path > query > extra).
  Object? operator [](String key) {
    final e = extra;
    return pathParams[key] ?? queryParams[key] ?? (e is Map ? e[key] : null);
  }

  static bool? _parseBool(String value) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') {
      return true;
    }
    if (lower == 'false' || lower == '0' || lower == 'no') {
      return false;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeleportRouteData &&
        other.routeName == routeName &&
        other.fullPath == fullPath;
  }

  @override
  int get hashCode => Object.hash(routeName, fullPath);
}

/// Internal implementation for path-based navigation.
class _PathRoute extends TeleportRouteData {
  @override
  final String fullPath;

  final Object? _extra;

  @override
  Object? get extra => _extra;

  const _PathRoute(this.fullPath, {Object? extra = const {}}) : _extra = extra;

  @override
  String? get routeName => null;

  @override
  LocalKey? get pageKey => null;
}

/// Internal implementation for current route data from context.
class _ContextRouteData extends TeleportRouteData {
  @override
  final String fullPath;

  @override
  final String? routeName;

  @override
  final Map<String, String> pathParams;

  @override
  final Map<String, String> queryParams;

  @override
  final LocalKey? pageKey;

  final Object? _extra;

  @override
  Object? get extra => _extra;

  const _ContextRouteData({
    required this.fullPath,
    required this.routeName,
    required this.pathParams,
    required this.queryParams,
    this.pageKey,
    Object? extra,
  }) : _extra = extra;
}

/// Extension on [BuildContext] for accessing current route data.
extension TeleportRouteDataExtension on BuildContext {
  /// Get the current route data.
  ///
  /// Example:
  /// ```dart
  /// final data = context.teleportRouteData;
  /// final userId = data.getInt('id');
  /// final name = data.getString('name');
  /// ```
  TeleportRouteData get teleportRouteData {
    return GoRouterStateData(GoRouterState.of(this));
  }
}

/// Implementation of [TeleportRouteData] that wraps [GoRouterState].
///
/// This is used efficiently internally to avoid copying maps.
class GoRouterStateData extends TeleportRouteData {
  final GoRouterState state;

  const GoRouterStateData(this.state);

  @override
  String? get routeName => state.name;

  @override
  String get fullPath => state.uri.toString();

  @override
  Uri get uri => state.uri;

  @override
  Map<String, String> get pathParams => state.pathParameters;

  @override
  Map<String, String> get queryParams => state.uri.queryParameters;

  @override
  Object? get extra => state.extra;

  @override
  Object? get error => state.error;

  @override
  LocalKey? get pageKey => state.pageKey;
}
