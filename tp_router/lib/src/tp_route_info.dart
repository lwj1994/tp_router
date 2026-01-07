import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tp_router_annotation/tp_router_annotation.dart';
import 'route.dart';

/// Function type for building a page widget from route data.
///
/// [data] contains all route parameters with type-safe access.
typedef TpPageBuilder = Widget Function(TpRouteData data);

/// Function type for building a shell widget (e.g. Scaffold with generic child).
typedef TpShellBuilder = Widget Function(BuildContext context, Widget child);

/// Abstract class for strongly-typed redirects.
abstract class TpRedirect<T extends TpRouteData> {
  const TpRedirect();
  FutureOr<TpRouteData?> handle(BuildContext context, T route);
}

/// Abstract base class for defining route topology.
abstract class TpRouteBase {
  const TpRouteBase();

  /// Convert to GoRouter's RouteBase.
  RouteBase toGoRoute({TpRouterConfig? config});
}

/// Represents a single route entry in the route table.
///
/// This class holds all information needed to create a GoRoute.
class TpRouteInfo extends TpRouteBase {
  /// The URL path pattern for this route.
  final String path;

  /// Optional route name for named navigation.
  final String? name;

  /// Builder function to create the page widget.
  final TpPageBuilder builder;

  /// Whether this is the initial/default route.
  final bool isInitial;

  /// Parameter metadata for documentation and validation.
  final List<TpParamInfo> params;

  /// Child routes.
  final List<TpRouteBase> children;

  /// Custom transition builder.
  final TpTransitionsBuilder? transition;

  /// Transition duration.
  final Duration transitionDuration;

  /// Reverse transition duration.
  final Duration reverseTransitionDuration;

  /// The redirect function for this route.
  final FutureOr<TpRouteData?> Function(
      BuildContext context, TpRouteData state)? redirect;

  /// Creates a [TpRouteInfo] instance.
  const TpRouteInfo({
    required this.path,
    required this.builder,
    this.name,
    this.isInitial = false,
    this.params = const [],
    this.children = const [],
    this.redirect,
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  });

  TpRouteData _buildRouteData(GoRouterState state) {
    final extraData = state.extra;
    return _ContextRouteData(
      fullPath: state.uri.toString(),
      pathParams: state.pathParameters,
      queryParams: state.uri.queryParameters,
      extra: extraData,
    );
  }

  FutureOr<String?> _handleRedirect(
      BuildContext context, GoRouterState state) async {
    if (redirect == null) return null;
    final data = _buildRouteData(state);
    final target = await redirect!(context, data);
    return target?.fullPath;
  }

  @override
  GoRoute toGoRoute({TpRouterConfig? config}) {
    // Determine transition to use
    final tb = transition ?? config?.defaultTransition;

    // Determine durations
    final tDur = transition != null
        ? transitionDuration
        : (config?.defaultTransitionDuration ?? transitionDuration);

    final rDur = transition != null
        ? reverseTransitionDuration
        : (config?.defaultReverseTransitionDuration ??
            reverseTransitionDuration);

    if (tb != null) {
      // Use pageBuilder for custom transitions
      return GoRoute(
        path: path,
        name: name,
        redirect: _handleRedirect,
        pageBuilder: (context, state) {
          final data = _buildRouteData(state);
          return CustomTransitionPage(
            key: state.pageKey,
            child: builder(data),
            transitionDuration: tDur,
            reverseTransitionDuration: rDur,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return tb.buildTransitions(
                  context, animation, secondaryAnimation, child);
            },
          );
        },
        routes: children.map((c) => c.toGoRoute(config: config)).toList(),
      );
    }

    // Default: use builder
    return GoRoute(
      path: path,
      name: name,
      redirect: _handleRedirect,
      builder: (context, state) {
        final data = _buildRouteData(state);
        return builder(data);
      },
      routes: children.map((c) => c.toGoRoute(config: config)).toList(),
    );
  }
}

/// Internal route data implementation for builder context.
class _ContextRouteData extends TpRouteData {
  @override
  final String fullPath;

  @override
  final Map<String, String> pathParams;

  @override
  final Map<String, String> queryParams;

  @override
  final dynamic extra;

  const _ContextRouteData({
    required this.fullPath,
    required this.pathParams,
    required this.queryParams,
    required this.extra,
  });
}

/// A shell route that wraps a child route with a shell UI.
///
/// This is typically used for Scaffolds with persistent bottom navigation.
class TpShellRouteInfo extends TpRouteBase {
  /// Builder for the shell UI.
  final TpShellBuilder builder;

  /// The list of routes that will be displayed within the shell.
  final List<TpRouteBase> routes;

  const TpShellRouteInfo({
    required this.builder,
    required this.routes,
  });

  @override
  RouteBase toGoRoute({TpRouterConfig? config}) {
    return ShellRoute(
      builder: (context, state, child) {
        // We wrap the GoRouter state away, exposing just context and child
        return builder(context, child);
      },
      routes: routes.map((r) => r.toGoRoute(config: config)).toList(),
    );
  }
}

/// Wrapper for StatefulNavigationShell to expose safe API.
class TpStatefulNavigationShell extends StatelessWidget {
  final StatefulNavigationShell _shell;
  const TpStatefulNavigationShell(this._shell, {super.key});

  /// The current branch index.
  int get currentIndex => _shell.currentIndex;

  /// Switch to a branch.
  void goBranch(int index, {bool initialLocation = false}) {
    _shell.goBranch(index, initialLocation: initialLocation);
  }

  @override
  Widget build(BuildContext context) => _shell;
}

/// Function type for building a stateful shell widget (uses navigationShell).
typedef TpStatefulShellBuilder = Widget Function(
  BuildContext context,
  TpStatefulNavigationShell navigationShell,
);

/// A stateful shell route using indexed stack.
class TpStatefulShellRouteInfo extends TpRouteBase {
  /// Builder for the shell UI.
  final TpStatefulShellBuilder builder;

  /// The branches (tabs), each containing a list of routes.
  final List<List<TpRouteBase>> branches;

  const TpStatefulShellRouteInfo({
    required this.builder,
    required this.branches,
  });

  @override
  RouteBase toGoRoute({TpRouterConfig? config}) {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return builder(context, TpStatefulNavigationShell(navigationShell));
      },
      branches: branches.map((routes) {
        return StatefulShellBranch(
          routes: routes.map((r) => r.toGoRoute(config: config)).toList(),
        );
      }).toList(),
    );
  }
}

/// Metadata about a route parameter.
class TpParamInfo {
  final String name;
  final String urlName;
  final String type;
  final bool isRequired;
  final Object? defaultValue;
  final String source;

  const TpParamInfo({
    required this.name,
    required this.urlName,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.source = 'auto',
  });
}
