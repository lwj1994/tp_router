class AnnotationResult {
  final String source;
  final String? name;

  AnnotationResult({required this.source, this.name});
}

class RedirectInfo {
  final String name;
  final String? importPath;
  final bool isClass;

  RedirectInfo({required this.name, this.importPath, this.isClass = false});
}

class PageBuilderInfo {
  final String name;
  final String? importPath;

  PageBuilderInfo({required this.name, this.importPath});
}

/// Base data for any route.
abstract class BaseRouteData {
  String get className;
  String get routeClassName;
}

/// Data for a standard route.
class RouteData implements BaseRouteData {
  @override
  final String className;
  @override
  final String routeClassName;
  final String path;
  final String
      originalPath; // The original path pattern (before resolving relative paths)
  final bool isInitial;
  final List<ParamData> params;
  final RedirectInfo? redirect;
  final String? transitionType;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final String? parentNavigatorKey;

  final String? onExit;
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final int? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final PageBuilderInfo? pageBuilder;
  final Set<String> extraImports;

  RouteData({
    required this.className,
    required this.routeClassName,
    required this.path,
    required this.originalPath,
    required this.isInitial,
    required this.params,
    this.redirect,
    this.transitionType,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.parentNavigatorKey,
    this.onExit,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.pageBuilder,
    this.extraImports = const {},
    this.pageType,
  });

  final String? pageType;
}

/// Data for a shell route.
class ShellRouteData implements BaseRouteData {
  @override
  final String className;
  @override
  final String routeClassName;
  final String navigatorKey;
  final String? parentNavigatorKey;
  final String? basePath; // Base path for relative child routes

  final bool isIndexedStack;
  final List<String> observers;

  final Set<String> extraImports;
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final int? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final PageBuilderInfo? pageBuilder;

  ShellRouteData({
    required this.className,
    required this.routeClassName,
    required this.navigatorKey,
    this.parentNavigatorKey,
    this.basePath,
    required this.isIndexedStack,
    this.observers = const [],
    this.extraImports = const {},
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.pageBuilder,
    this.pageType,
    this.branchKeys = const [],
  });

  final String? pageType;
  final List<String> branchKeys;
}

/// Data for a parameter.
class ParamData {
  final String name;
  final String urlName;
  final String type;
  final String baseType;
  final bool isRequired;
  final bool isNullable;
  final bool isNamed;
  final String source;
  final String? defaultValueCode;
  final String? importPath;

  ParamData({
    required this.name,
    required this.urlName,
    required this.type,
    required this.baseType,
    required this.isRequired,
    required this.isNullable,
    required this.isNamed,
    required this.source,
    this.defaultValueCode,
    this.importPath,
  });
}
