import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teleport_router/src/transitions.dart';
import 'package:teleport_router_annotation/teleport_router_annotation.dart';
import 'navi_key.dart';
import 'page_factory.dart';
import 'route.dart';
import 'swipe_back.dart';

/// Function type for building a page widget from route data.
///
/// [data] contains all route parameters with type-safe access.
typedef TeleportPageBuilder = Widget Function(TeleportRouteData data);

/// Function type for building a shell widget (e.g. Scaffold with generic child).
typedef TeleportShellBuilder = Widget Function(
    BuildContext context, Widget child);

/// Abstract class for strongly-typed redirects.
abstract class TeleportRedirect<T extends TeleportRouteData> {
  const TeleportRedirect();
  FutureOr<TeleportRouteData?> handle(BuildContext context, T route);
}

/// Abstract class for strongly-typed exit logic.
abstract class TeleportOnExit<T extends TeleportRouteData> {
  const TeleportOnExit();
  FutureOr<bool> onExit(BuildContext context, T state);
}

/// Abstract base class for defining route topology.
abstract class TeleportRouteBase {
  const TeleportRouteBase();

  /// Convert to GoRouter's RouteBase.
  RouteBase toGoRoute({TeleportRouterConfig? config});
}

/// Represents a single route entry in the route table.
///
/// This class holds all information needed to create a GoRoute.
class TeleportRouteInfo extends TeleportRouteBase {
  /// The URL path pattern for this route.
  final String path;

  /// Optional route name for named navigation.
  final String? name;

  /// Builder function to create the page widget.
  final TeleportPageBuilder builder;

  /// Whether this is the initial/default route.
  final bool isInitial;

  /// Parameter metadata for documentation and validation.
  final List<TeleportParamInfo> params;

  /// Custom transition builder.
  final TeleportTransitionsBuilder? transition;

  /// Transition duration.
  final Duration transitionDuration;

  /// Reverse transition duration.
  final Duration reverseTransitionDuration;

  /// The redirect function for this route.
  final FutureOr<TeleportRouteData?> Function(
      BuildContext context, TeleportRouteData state)? redirect;

  /// Creates a [TeleportRouteInfo] instance.
  const TeleportRouteInfo({
    required this.path,
    required this.builder,
    this.name,
    this.isInitial = false,
    this.params = const [],
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
    this.pageBuilder,
    this.type,
  });

  /// The specific type of page to construct.
  final TeleportPageType? type;

  /// Custom Page factory.
  final TeleportPageFactory? pageBuilder;

  /// Logic when route executes onExit.
  final FutureOr<bool> Function(BuildContext, TeleportRouteData)? onExit;

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
  GoRoute toGoRoute({TeleportRouterConfig? config}) {
    // Use pageBuilder for custom transitions
    return GoRoute(
      path: path,
      name: name,
      onExit: onExit != null
          ? (context, state) => onExit!(context, _buildRouteData(state))
          : null,
      parentNavigatorKey: parentNavigatorKey,
      redirect: _handleRedirect,
      pageBuilder: (context, state) {
        final data = _buildRouteData(state);
        final child = builder(data);

        return _createTeleportPage(
          context: context,
          state: state,
          data: data,
          child: child,
          pageConfig: TeleportPageConfig(
            pageBuilder: pageBuilder,
            transitionBuilder: transition,
            fullscreenDialog: fullscreenDialog,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierColor: barrierColor,
            barrierLabel: barrierLabel,
            maintainState: maintainState,
            transitionDuration: transitionDuration,
            reverseTransitionDuration: reverseTransitionDuration,
            type: type,
          ),
          routerConfig: config,
        );
      },
    );
  }
}

/// A shell route that wraps a child route with a shell UI.
///
/// This is typically used for Scaffolds with persistent bottom navigation.
class TeleportShellRouteInfo extends TeleportRouteBase {
  /// Builder for the shell UI.
  final TeleportShellBuilder builder;

  /// The list of routes that will be displayed within the shell.
  final List<TeleportRouteBase> routes;

  /// Optional navigator key for this shell.
  /// When provided, a TeleportRouteObserver is automatically injected.
  final TeleportNavKey? navigatorKey;

  /// Optional parent navigator key.
  final TeleportNavKey? parentNavigatorKey;

  /// Additional observers for the navigator.
  /// Note: TeleportRouteObserver is automatically added when navigatorKey is set.
  final List<NavigatorObserver>? observers;

  /// Page configuration.
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;

  const TeleportShellRouteInfo({
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
    this.pageBuilder,
    this.type,
  });

  /// The specific type of page to construct.
  final TeleportPageType? type;

  /// Custom Page Factory.
  final TeleportPageFactory? pageBuilder;

  @override
  RouteBase toGoRoute({TeleportRouterConfig? config}) {
    // Auto-inject TeleportRouteObserver when navigatorKey is provided
    final effectiveObservers = <NavigatorObserver>[
      if (navigatorKey != null) navigatorKey!.observer,
      ...?observers,
    ];

    return ShellRoute(
      navigatorKey: navigatorKey?.globalKey,
      parentNavigatorKey: parentNavigatorKey?.globalKey,
      observers: effectiveObservers.isNotEmpty ? effectiveObservers : null,
      pageBuilder: (context, state, child) {
        final data = _buildRouteData(state);
        final shellChild = builder(context, child);
        return _createTeleportPage(
          context: context,
          state: state,
          data: data,
          child: shellChild,
          pageConfig: TeleportPageConfig(
            pageBuilder: pageBuilder,
            transitionBuilder: const TeleportNoTransition(),
            fullscreenDialog: fullscreenDialog,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierColor: barrierColor,
            barrierLabel: barrierLabel,
            maintainState: maintainState,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            type: type,
          ),
          routerConfig: config,
        );
      },
      routes: routes.map((r) => r.toGoRoute(config: config)).toList(),
    );
  }
}

/// Wrapper for StatefulNavigationShell to expose safe API.
class TeleportStatefulNavigationShell extends StatelessWidget {
  final StatefulNavigationShell _shell;
  final int _branchCount;

  const TeleportStatefulNavigationShell(this._shell, this._branchCount,
      {super.key});

  /// The current branch index.
  int get currentIndex => _shell.currentIndex;

  /// Switch to a branch.
  void teleport(int index, {bool popToInitial = false}) {
    if (index < 0 || index >= _branchCount) {
      throw RangeError.range(
          index, 0, _branchCount - 1, 'index', 'Branch index out of bounds');
    }
    _shell.goBranch(index, initialLocation: popToInitial);
  }

  @override
  Widget build(BuildContext context) => _shell;
}

/// Function type for building a stateful shell widget (uses navigationShell).
typedef TeleportStatefulShellBuilder = Widget Function(
  BuildContext context,
  TeleportStatefulNavigationShell navigationShell,
);

/// A shell route that maintains state for its branches (StatefulShellRoute).
///
/// This is typically used for applications with a bottom navigation bar, where
/// each tab (branch) maintains its own navigation stack and state.
///
/// ## Usage
/// - [branches]: Defines the route stack for each tab.
/// - [branchNavigatorKeys]: Optional [TeleportNavKey]s for each branch. Providing these
///   enables advanced features like `popToInitial()` or `popUntil()` for specific tabs.
///
/// **Note**: If [branchNavigatorKeys] is provided, its length must match [branches].
class TeleportStatefulShellRouteInfo extends TeleportRouteBase {
  /// Builder for the shell UI.
  final TeleportStatefulShellBuilder builder;

  /// The branches (tabs), each containing a list of routes.
  final List<List<TeleportRouteBase>> branches;

  /// Optional navigator keys for each branch.
  /// When provided, TeleportRouteObserver is automatically injected for each branch.
  final List<TeleportNavKey>? branchNavigatorKeys;

  /// Optional parent navigator key.
  final TeleportNavKey? parentNavigatorKey;

  /// Page configuration.
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;

  /// Additional observer builder for branches.
  /// Note: TeleportRouteObserver is automatically added for each branch with a key.
  final List<NavigatorObserver> Function()? observersBuilder;

  const TeleportStatefulShellRouteInfo({
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
    this.observersBuilder,
    this.pageBuilder,
    this.type,
  });

  /// The specific type of page to construct.
  final TeleportPageType? type;

  /// Custom Page Factory.
  final TeleportPageFactory? pageBuilder;

  @override
  RouteBase toGoRoute({TeleportRouterConfig? config}) {
    // Validate branchNavigatorKeys length if provided
    assert(
      branchNavigatorKeys == null ||
          branchNavigatorKeys!.length == branches.length,
      'branchNavigatorKeys length (${branchNavigatorKeys?.length}) must match '
      'branches length (${branches.length})',
    );

    return StatefulShellRoute.indexedStack(
      parentNavigatorKey: parentNavigatorKey?.globalKey,
      pageBuilder: (context, state, navigationShell) {
        final data = _buildRouteData(state);
        final shellChild = builder(context,
            TeleportStatefulNavigationShell(navigationShell, branches.length));

        return _createTeleportPage(
          context: context,
          state: state,
          data: data,
          child: shellChild,
          pageConfig: TeleportPageConfig(
            pageBuilder: pageBuilder,
            transitionBuilder: const TeleportNoTransition(),
            fullscreenDialog: fullscreenDialog,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierColor: barrierColor,
            barrierLabel: barrierLabel,
            maintainState: maintainState,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            type: type,
          ),
          routerConfig: config,
        );
      },
      branches: branches.asMap().entries.map((entry) {
        final index = entry.key;
        final routes = entry.value;

        // Get the TeleportNavKey for this branch if available
        final branchKey =
            branchNavigatorKeys != null && index < branchNavigatorKeys!.length
                ? branchNavigatorKeys![index]
                : null;

        // Build observers list with auto-injected TeleportRouteObserver
        final branchObservers = <NavigatorObserver>[
          if (branchKey != null) branchKey.observer,
          ...?observersBuilder?.call(),
        ];

        return StatefulShellBranch(
          navigatorKey: branchKey?.globalKey,
          routes: routes.map((r) => r.toGoRoute(config: config)).toList(),
          observers: branchObservers.isNotEmpty ? branchObservers : null,
        );
      }).toList(),
    );
  }
}

/// Metadata about a route parameter.
class TeleportParamInfo {
  final String name;
  final String urlName;
  final String type;
  final bool isRequired;
  final Object? defaultValue;
  final String source;

  const TeleportParamInfo({
    required this.name,
    required this.urlName,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.source = 'auto',
  });
}

TeleportRouteData _buildRouteData(GoRouterState state) {
  return GoRouterStateData(state);
}

/// Configuration object for page creation.
///
/// Encapsulates all the settings required to build a [Page] from a route.
class TeleportPageConfig {
  final TeleportPageFactory? pageBuilder;
  final TeleportTransitionsBuilder? transitionBuilder;
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final TeleportPageType? type;

  const TeleportPageConfig({
    required this.fullscreenDialog,
    required this.opaque,
    required this.barrierDismissible,
    required this.maintainState,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    this.pageBuilder,
    this.transitionBuilder,
    this.barrierColor,
    this.barrierLabel,
    this.type,
  });
}

Page<dynamic> _createTeleportPage({
  required BuildContext context,
  required GoRouterState state,
  required TeleportRouteData data,
  required Widget child,
  required TeleportPageConfig pageConfig,
  TeleportRouterConfig? routerConfig,
}) {
  final effectivePageBuilder =
      pageConfig.pageBuilder ?? routerConfig?.defaultPageBuilder;
  if (effectivePageBuilder != null) {
    return effectivePageBuilder.buildPage(context, data, child);
  }

  // Resolve transition defaults
  final effectiveTransition =
      pageConfig.transitionBuilder ?? routerConfig?.defaultTransition;

  var tDur = pageConfig.transitionDuration;
  var rDur = pageConfig.reverseTransitionDuration;

  // Only override durations if using default transition (i.e. no explicit transition on route)
  if (pageConfig.transitionBuilder == null) {
    if (routerConfig?.defaultTransitionDuration != null) {
      tDur = routerConfig!.defaultTransitionDuration!;
    }
    if (routerConfig?.defaultReverseTransitionDuration != null) {
      rDur = routerConfig!.defaultReverseTransitionDuration!;
    }
  }

  // Determine effective page type
  var effectiveType =
      pageConfig.type ?? routerConfig?.defaultPageType ?? TeleportPageType.auto;

  // Resolve 'auto' to specific type if native behavior is desired
  if (effectiveType == TeleportPageType.auto) {
    // Only resolve to native page if no custom transition/dialog settings
    if (effectiveTransition == null &&
        pageConfig.opaque &&
        pageConfig.barrierColor == null &&
        !pageConfig.barrierDismissible) {
      final platform = Theme.of(context).platform;
      effectiveType =
          (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
              ? TeleportPageType.cupertino
              : TeleportPageType.material;
    }
  }

  // Construct specific pages
  switch (effectiveType) {
    case TeleportPageType.cupertino:
      return CupertinoPage(
        child: child,
        name: state.name,
        arguments: data,
        key: state.pageKey,
        fullscreenDialog: pageConfig.fullscreenDialog,
        maintainState: pageConfig.maintainState,
      );
    case TeleportPageType.swipeBack:
      return CustomTransitionPage(
        arguments: data,
        name: state.name,
        fullscreenDialog: pageConfig.fullscreenDialog,
        opaque: false,
        barrierColor: pageConfig.barrierColor,
        barrierDismissible: pageConfig.barrierDismissible,
        barrierLabel: pageConfig.barrierLabel,
        maintainState: pageConfig.maintainState,
        key: state.pageKey,
        child: SwipeBackWrapper(
          child: child,
          edgeWidth: null, // Allow swipe from anywhere
        ),
        transitionDuration: tDur,
        reverseTransitionDuration: rDur,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return TeleportSlideTransition()
              .buildTransitions(context, animation, secondaryAnimation, child);
        },
      );
    case TeleportPageType.material:
      return MaterialPage(
        child: child,
        name: state.name,
        arguments: data,
        key: state.pageKey,
        fullscreenDialog: pageConfig.fullscreenDialog,
        maintainState: pageConfig.maintainState,
      );
    default:
      // Fall through to CustomTransitionPage
      break;
  }

  return CustomTransitionPage(
    arguments: data,
    name: state.name,
    fullscreenDialog: pageConfig.fullscreenDialog,
    opaque: pageConfig.opaque,
    barrierColor: pageConfig.barrierColor,
    barrierDismissible: pageConfig.barrierDismissible,
    barrierLabel: pageConfig.barrierLabel,
    maintainState: pageConfig.maintainState,
    key: state.pageKey,
    child: child,
    transitionDuration: tDur,
    reverseTransitionDuration: rDur,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return (effectiveTransition ?? const TeleportCupertinoPageTransition())
          .buildTransitions(context, animation, secondaryAnimation, child);
    },
  );
}
