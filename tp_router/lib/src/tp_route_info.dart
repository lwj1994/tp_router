import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tp_router/src/transitions.dart';
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
    this.onExit,
    this.parentNavigatorKey,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
  });

  /// Logic when route executes onExit.
  final FutureOr<bool> Function(BuildContext, GoRouterState)? onExit;

  /// Optional parent navigator key for this route.
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Whether this page is a fullscreen dialog.
  final bool fullscreenDialog;

  /// Whether the page is opaque.
  final bool opaque;

  /// Whether clicking the barrier dismisses the page.
  final bool barrierDismissible;

  /// The color of the barrier.
  final Color? barrierColor;

  /// Semantic label for the barrier.
  final String? barrierLabel;

  /// Whether to maintain state.
  final bool maintainState;

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
    final tb =
        transition ?? config?.defaultTransition ?? TpCupertinoPageTransition();

    // Determine durations
    final tDur = transition != null
        ? transitionDuration
        : (config?.defaultTransitionDuration ?? transitionDuration);

    final rDur = transition != null
        ? reverseTransitionDuration
        : (config?.defaultReverseTransitionDuration ??
            reverseTransitionDuration);

    // Use pageBuilder for custom transitions
    return GoRoute(
      path: path,
      name: name,
      onExit: onExit,
      parentNavigatorKey: parentNavigatorKey,
      redirect: _handleRedirect,
      pageBuilder: (context, state) {
        final data = _buildRouteData(state);
        return CustomTransitionPage(
          arguments: state.extra,
          name: state.name,
          fullscreenDialog: fullscreenDialog,
          opaque: opaque,
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          maintainState: maintainState,
          key: state.pageKey,
          child: builder(data),
          transitionDuration: tDur,
          reverseTransitionDuration: rDur,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return tb.buildTransitions(
                context, animation, secondaryAnimation, child);
          },
        );
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

  /// Optional navigator key for this shell.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional parent navigator key.
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// List of observers for the navigator.
  final List<NavigatorObserver>? observers;

  /// Page configuration.
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;

  /// Transition configuration.
  final TpTransitionsBuilder? transition;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  const TpShellRouteInfo({
    required this.builder,
    required this.routes,
    this.navigatorKey,
    this.parentNavigatorKey,
    this.observers,
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.transition,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  });

  @override
  RouteBase toGoRoute({TpRouterConfig? config}) {
    // Determine transition
    final tb = transition ?? const TpNoTransition();

    return ShellRoute(
      navigatorKey: navigatorKey,
      parentNavigatorKey: parentNavigatorKey,
      observers: observers,
      pageBuilder: (context, state, child) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: builder(context, child),
          fullscreenDialog: fullscreenDialog,
          opaque: opaque,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          barrierLabel: barrierLabel,
          maintainState: maintainState,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return tb.buildTransitions(
                context, animation, secondaryAnimation, child);
          },
        );
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

  /// Optional navigator keys for each branch.
  final List<GlobalKey<NavigatorState>>? branchNavigatorKeys;

  /// Optional parent navigator key.
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Page configuration.
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;

  /// Transition configuration.
  final TpTransitionsBuilder? transition;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  /// Builder for navigator observers.
  /// Used to create fresh observer instances for each branch.
  final List<NavigatorObserver> Function()? observersBuilder;

  const TpStatefulShellRouteInfo({
    required this.builder,
    required this.branches,
    this.branchNavigatorKeys,
    this.parentNavigatorKey,
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.transition,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
    this.observersBuilder,
  });

  @override
  RouteBase toGoRoute({TpRouterConfig? config}) {
    // Determine transition
    final tb = transition ?? const TpNoTransition();

    return StatefulShellRoute.indexedStack(
      parentNavigatorKey: parentNavigatorKey,
      pageBuilder: (context, state, navigationShell) {
        return CustomTransitionPage(
          arguments: state.extra,
          name: state.name,
          fullscreenDialog: fullscreenDialog,
          opaque: opaque,
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          maintainState: maintainState,
          key: state.pageKey,
          child: builder(context, TpStatefulNavigationShell(navigationShell)),
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return tb.buildTransitions(
                context, animation, secondaryAnimation, child);
          },
        );
      },
      branches: branches.asMap().entries.map((entry) {
        final index = entry.key;
        final routes = entry.value;
        return StatefulShellBranch(
          navigatorKey:
              branchNavigatorKeys != null && index < branchNavigatorKeys!.length
                  ? branchNavigatorKeys![index]
                  : null,
          routes: routes.map((r) => r.toGoRoute(config: config)).toList(),
          observers: observersBuilder?.call(),
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

TpRouteData _buildRouteData(GoRouterState state) {
  final extraData = state.extra;
  return _ContextRouteData(
    fullPath: state.uri.toString(),
    pathParams: state.pathParameters,
    queryParams: state.uri.queryParameters,
    extra: extraData,
  );
}
