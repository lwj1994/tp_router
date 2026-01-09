import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tp_router/src/tp_router.dart';
import 'package:tp_router_annotation/tp_router_annotation.dart';
import 'navi_key.dart';
import 'page_factory.dart';

/// Configuration for TpRouter options.
class TpRouterConfig {
  final TpTransitionsBuilder? defaultTransition;
  final Duration? defaultTransitionDuration;
  final Duration? defaultReverseTransitionDuration;

  const TpRouterConfig({
    this.defaultTransition,
    this.defaultTransitionDuration,
    this.defaultReverseTransitionDuration,
    this.defaultPageType,
    this.defaultPageBuilder,
  });

  final TpPageType? defaultPageType;
  final TpPageFactory? defaultPageBuilder;
}

/// Base class for all route objects used in navigation.
///
/// This class serves two purposes:
/// 1. For navigation: Use generated route classes or [TpRouteData.fromPath]
/// 2. For reading current route: Use [TpRouteData.of(context)] or `context.tpRouteData`
///
/// Example:
/// ```dart
/// // Navigation
/// TpRouter.instance.tp(HomeRoute());
/// TpRouter.instance.tp(TpRouteData.fromPath('/user/123'));
///
/// // Reading current route parameters
/// final data = context.tpRouteData;
/// final userId = data.getInt('id');
/// ```
abstract class TpRouteData {
  /// The full path of the route including query parameters.
  String get fullPath;

  /// The URI of the current route.
  Uri get uri => Uri.parse(fullPath);

  /// Path parameters extracted from the URL.
  Map<String, String> get pathParams => const {};

  /// Query parameters from the URL.
  Map<String, String> get queryParams => const {};

  /// Extra data passed to the route.
  dynamic get extra => null;

  /// Error associated with this route, if any.
  Object? get error => null;

  /// The page key used by GoRouter (useful for maintaining state).
  LocalKey? get pageKey => null;

  /// The name of the route (null if not named).
  String? get routeName;

  const TpRouteData();

  /// Creates a [TpRouteData] from a path string for navigation.
  ///
  /// Example:
  /// ```dart
  /// TpRouter.instance.tp(TpRouteData.fromPath('/user/123'));
  /// TpRouter.instance.tp(TpRouteData.fromPath('/home', extra: {'key': 'value'}));
  /// ```
  factory TpRouteData.fromPath(String path, {Object? extra = const {}}) {
    return _PathRoute(path, extra: extra);
  }

  /// Gets the current route data from the given [context].
  ///
  /// Example:
  /// ```dart
  /// final data = TpRouteData.of(context);
  /// final userId = data.getInt('id');
  /// ```
  static TpRouteData of(BuildContext context) {
    return context.tpRouteData;
  }

  /// Navigate to this route.
  ///
  /// [context]: Optional BuildContext for context-aware navigation.
  /// [clearHistory]: If true, clears navigation history (like `go`).
  /// [replacement]: If true, replaces the current route.
  /// [navigatorKey]: Targets a specific navigator by its [TpNavKey].
  ///
  /// Example:
  /// ```dart
  /// // Navigate (uses TpRouter.instance)
  /// UserRoute(id: 123).tp();
  ///
  /// // Navigate to specific navigator
  /// DetailsRoute().tp(navigatorKey: const MainDashBoradNavKey());
  ///
  /// // Wait for result
  /// final result = await SelectRoute().tp<String>();
  /// ```
  Future<T?> tp<T extends Object?>({
    bool clearHistory = false,
    bool replacement = false,
    TpNavKey? navigatorKey,
  }) {
    return TpRouter.instance.tp<T>(
      this,
      isReplace: replacement,
      isClearHistory: clearHistory,
      navigatorKey: navigatorKey,
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
    if (e.containsKey(key)) {
      return e[key] as T?;
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
  dynamic operator [](String key) {
    return pathParams[key] ?? queryParams[key] ?? extra[key];
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
    return other is TpRouteData &&
        other.routeName == routeName &&
        other.fullPath == fullPath;
  }

  @override
  int get hashCode => Object.hash(routeName, fullPath);
}

/// Internal implementation for path-based navigation.
class _PathRoute extends TpRouteData {
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
class _ContextRouteData extends TpRouteData {
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

  final Map<String, dynamic> _extra;

  @override
  Map<String, dynamic> get extra => _extra;

  const _ContextRouteData({
    required this.fullPath,
    required this.routeName,
    required this.pathParams,
    required this.queryParams,
    this.pageKey,
    required Map<String, dynamic> extra,
  }) : _extra = extra;
}

/// Extension on [BuildContext] for accessing current route data.
extension TpRouteDataExtension on BuildContext {
  /// Get the current route data.
  ///
  /// Example:
  /// ```dart
  /// final data = context.tpRouteData;
  /// final userId = data.getInt('id');
  /// final name = data.getString('name');
  /// ```
  TpRouteData get tpRouteData {
    final state = GoRouterState.of(this);
    final extraData = state.extra;
    return _ContextRouteData(
      fullPath: state.uri.toString(),
      routeName: state.name ?? state.uri.toString(),
      pathParams: state.pathParameters,
      queryParams: state.uri.queryParameters,
      pageKey: state.pageKey,
      extra: extraData is Map<String, dynamic> ? extraData : const {},
    );
  }
}
