import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that collects all @TpRoute annotations and generates
/// a single tp_router.gr.dart file.
class TpRouterBuilder implements Builder {
  static const _tpRouteChecker = TypeChecker.fromUrl(
    'package:tp_router_annotation/src/tp_route.dart#TpRoute',
  );
  static const _tpShellRouteChecker = TypeChecker.fromUrl(
    'package:tp_router_annotation/src/tp_route.dart#TpShellRoute',
  );
  static const _pathChecker = TypeChecker.fromUrl(
    'package:tp_router_annotation/src/tp_route.dart#Path',
  );
  static const _queryChecker = TypeChecker.fromUrl(
    'package:tp_router_annotation/src/tp_route.dart#Query',
  );

  final String output;

  TpRouterBuilder({this.output = 'lib/tp_router.gr.dart'});

  @override
  Map<String, List<String>> get buildExtensions => {
        r'lib/$lib$': [output],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final allRoutes = <_BaseRouteData>[];
    final imports = <String>{};

    // Find all Dart files in lib/
    await for (final input in buildStep.findAssets(Glob('lib/**/*.dart'))) {
      // Skip generated files
      if (input.path.endsWith('.g.dart')) continue;

      try {
        final library = await buildStep.resolver.libraryFor(input);
        final reader = LibraryReader(library);

        // Find all classes with @TpRoute annotation
        for (final annotated in reader.annotatedWith(_tpRouteChecker)) {
          final element = annotated.element;
          if (element is! ClassElement) continue;

          final routeData = _analyzeRoute(
            element,
            annotated.annotation,
            input.path,
          );

          if (routeData != null) {
            allRoutes.add(routeData);
            // Add import for the source file
            final importPath = input.path.replaceFirst(
              'lib/',
              'package:${buildStep.inputId.package}/',
            );
            imports.add(importPath);
            imports.addAll(routeData.extraImports);

            // Add redirect import if present
            if (routeData.redirect?.importPath != null) {
              imports.add(routeData.redirect!.importPath!);
            }

            // Add imports for complex types in parameters
            for (final param in routeData.params) {
              if (param.importPath != null) {
                imports.add(param.importPath!);
              }
            }
          }
        }

        // Find all classes with @TpShellRoute annotation
        for (final annotated in reader.annotatedWith(_tpShellRouteChecker)) {
          final element = annotated.element;
          if (element is! ClassElement) continue;

          final shellData = _analyzeShellRoute(element, annotated.annotation);

          if (shellData != null) {
            allRoutes.add(shellData);
            // Add import for the source file
            final importPath = input.path.replaceFirst(
              'lib/',
              'package:${buildStep.inputId.package}/',
            );
            imports.add(importPath);
            imports.addAll(shellData.extraImports);
          }
        }
      } catch (e) {
        // Skip files that can't be resolved
        continue;
      }
    }

    // Validate duplicate paths
    _validateDuplicatePaths(allRoutes);

    if (allRoutes.isNotEmpty) {
      final content = _generateFile(allRoutes, imports);
      final outputId = AssetId(buildStep.inputId.package, output);
      await buildStep.writeAsString(outputId, content);
    }
  }

  void _validateDuplicatePaths(List<_BaseRouteData> routes) {
    final pathMap = <String, String>{}; // Path -> RouteClassName

    for (final route in routes) {
      if (route is _RouteData) {
        final path = route.path;
        // Ignore checking parameters inside path logic for strict duplicates for now,
        // just exact string match.
        if (pathMap.containsKey(path)) {
          throw InvalidGenerationSourceError(
            'Duplicate path found: "$path" is defined in both ${pathMap[path]} and ${route.routeClassName}. Paths must be unique.',
          );
        }
        pathMap[path] = route.routeClassName;
      }
    }
  }

  /// Analyzes a class with @TpRoute annotation.
  _RouteData? _analyzeRoute(
    ClassElement classElement,
    ConstantReader annotation,
    String sourcePath,
  ) {
    final className = classElement.name;

    // Generate route class name (remove Page/Screen suffix)
    final routeClassName = _generateRouteClassName(className!);

    // Extract annotation values
    var path = annotation.peek('path')?.stringValue;

    // Auto-generate path if missing or empty
    if (path == null || path.isEmpty) {
      path = _generateKebabCasePath(className);
    }

    final name = annotation.peek('name')?.stringValue;
    final isInitial = annotation.read('isInitial').boolValue;

    // Analyze constructor parameters
    final constructor = classElement.unnamedConstructor;
    if (constructor == null) return null;

    // Collect parameter info
    final params = <_ParamData>[];
    for (final param in constructor.formalParameters) {
      // Skip 'key' parameter for widgets
      if (param.name == 'key') continue;

      final paramData = _analyzeParameter(param, classElement);
      if (paramData != null) {
        params.add(paramData);
      }
    }

    // Extract parentNavigatorKey and branchIndex for shell route association
    final parentNavigatorKey =
        annotation.peek('parentNavigatorKey')?.stringValue;
    final branchIndex = annotation.peek('branchIndex')?.intValue ?? 0;

    final extraImports = <String>{};

    // Extract onExit
    String? onExit;
    final onExitReader = annotation.peek('onExit');
    if (onExitReader != null && !onExitReader.isNull) {
      final func = onExitReader.objectValue.toFunctionValue();
      if (func != null) {
        onExit = func.name;
        extraImports.add(func.library.identifier);
      }
    }

    final fullscreenDialog =
        annotation.peek('fullscreenDialog')?.boolValue ?? false;
    final opaque = annotation.peek('opaque')?.boolValue ?? true;
    final barrierDismissible =
        annotation.peek('barrierDismissible')?.boolValue ?? false;

    // Extract barrierColor (Color object)
    int? barrierColor;
    final colorReader = annotation.peek('barrierColor');
    if (colorReader != null && !colorReader.isNull) {
      barrierColor = colorReader.objectValue.getField('value')?.toIntValue();
    }

    final barrierLabel = annotation.peek('barrierLabel')?.stringValue;
    final maintainState = annotation.peek('maintainState')?.boolValue ?? true;

    return _RouteData(
      className: className,
      routeClassName: routeClassName,
      path: path,
      name: name,
      isInitial: isInitial,
      params: params,
      redirect: _extractRedirect(annotation),
      transitionType: _extractTransitionType(annotation),
      transitionDuration: _extractDuration(annotation, 'transitionDuration'),
      reverseTransitionDuration: _extractDuration(
        annotation,
        'reverseTransitionDuration',
      ),
      parentNavigatorKey: parentNavigatorKey,
      branchIndex: branchIndex,
      onExit: onExit,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
      extraImports: extraImports,
    );
  }

  RedirectInfo? _extractRedirect(ConstantReader annotation) {
    final redirectReader = annotation.peek('redirect');
    if (redirectReader == null || redirectReader.isNull) return null;

    final redirectObj = redirectReader.objectValue;

    // Check if it's a Type (Class)
    final typeValue = redirectObj.toTypeValue();
    if (typeValue != null) {
      final element = typeValue.element;
      if (element is ClassElement && element.name != null) {
        return RedirectInfo(
          name: element.name!,
          importPath: element.library.identifier,
          isClass: true,
        );
      }
    }

    // Check if it's a function
    final funcValue = redirectObj.toFunctionValue();
    if (funcValue != null && funcValue.name != null) {
      return RedirectInfo(
        name: funcValue.name!,
        importPath: funcValue.library.identifier,
        isClass: false,
      );
    }

    return null;
  }

  String _generateKebabCasePath(String className) {
    var name = className;
    if (name.endsWith('Page')) {
      name = name.substring(0, name.length - 4);
    } else if (name.endsWith('Screen')) {
      name = name.substring(0, name.length - 6);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      final char = name[i];
      if (i > 0 && char == char.toUpperCase()) {
        buffer.write('-');
      }
      buffer.write(char.toLowerCase());
    }
    return '/${buffer.toString()}';
  }

  /// Extracts the transition type name from annotation.
  String? _extractTransitionType(ConstantReader annotation) {
    final tbReader = annotation.peek('transition');
    if (tbReader == null || tbReader.isNull) return null;

    final tbValue = tbReader.objectValue;
    final tbType = tbValue.type;
    if (tbType == null) return null;

    final element = tbType.element;
    if (element == null) return null;

    return element.name;
  }

  /// Extracts Duration from annotation field.
  Duration _extractDuration(ConstantReader annotation, String fieldName) {
    final durationReader = annotation.peek(fieldName);
    if (durationReader == null || durationReader.isNull) {
      return const Duration(milliseconds: 300);
    }

    final durationValue = durationReader.objectValue;
    // Duration stores microseconds internally in _duration field
    final micros = durationValue.getField('_duration')?.toIntValue() ?? 300000;
    return Duration(microseconds: micros);
  }

  /// Analyzes a class with @TpShellRoute annotation.
  _ShellRouteData? _analyzeShellRoute(
    Element element,
    ConstantReader annotation,
  ) {
    if (element is! ClassElement) return null;
    final className = element.name;
    if (className == null) return null;
    final routeClassName = _generateRouteClassName(className);

    final navigatorKey = annotation.read('navigatorKey').stringValue;
    final parentNavigatorKey =
        annotation.peek('parentNavigatorKey')?.stringValue;
    final branchIndex = annotation.peek('branchIndex')?.intValue ?? 0;
    final isIndexedStack = annotation.read('isIndexedStack').boolValue;

    final extraImports = <String>{};

    // Extract observers
    final observers = <String>[];
    final observersReader = annotation.peek('observers');
    if (observersReader != null) {
      final list = observersReader.listValue;
      for (final item in list) {
        final type = item.toTypeValue();
        if (type != null && type.element != null) {
          observers.add(type.element!.name!);
          if (type.element!.library != null) {
            extraImports.add(type.element!.library!.identifier);
          }
        }
      }
    }

    // Extract page config
    final fullscreenDialog =
        annotation.peek('fullscreenDialog')?.boolValue ?? false;
    final opaque = annotation.peek('opaque')?.boolValue ?? false;
    final barrierDismissible =
        annotation.peek('barrierDismissible')?.boolValue ?? false;
    final barrierLabel = annotation.peek('barrierLabel')?.stringValue;
    final maintainState = annotation.peek('maintainState')?.boolValue ?? true;

    // Extract barrierColor (Color object)
    int? barrierColor;
    final colorReader = annotation.peek('barrierColor');
    if (colorReader != null && !colorReader.isNull) {
      barrierColor = colorReader.objectValue.getField('value')?.toIntValue();
    }

    return _ShellRouteData(
      className: className,
      routeClassName: routeClassName,
      navigatorKey: navigatorKey,
      parentNavigatorKey: parentNavigatorKey,
      branchIndex: branchIndex,
      isIndexedStack: isIndexedStack,
      observers: observers,
      extraImports: extraImports,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
      transitionType: _extractTransitionType(annotation),
      transitionDuration: _extractDuration(annotation, 'transitionDuration'),
      reverseTransitionDuration: _extractDuration(
        annotation,
        'reverseTransitionDuration',
      ),
    );
  }

  /// Generates route class name by removing Page/Screen suffix.
  String _generateRouteClassName(String className) {
    String result = className;
    if (result.endsWith('Page')) {
      result = result.substring(0, result.length - 4);
    } else if (result.endsWith('Screen')) {
      result = result.substring(0, result.length - 6);
    }
    return '${result}Route';
  }

  _ParamData? _analyzeParameter(
    FormalParameterElement param,
    ClassElement classElement,
  ) {
    final paramName = param.name;
    if (paramName == null) return null;
    final paramType = param.type;
    final typeStr = paramType.getDisplayString();
    final isNullable =
        paramType.nullabilitySuffix == NullabilitySuffix.question;
    final isRequired = param.isRequired && !isNullable;

    // Determine source from annotations
    String? customName;
    String source = 'extra';
    String? importPath;

    final typeElement = paramType.element;
    if (typeElement != null &&
        typeElement.library != null &&
        !typeElement.library!.isDartCore) {
      importPath = typeElement.library!.identifier;
    }

    // Check field annotations first
    final field = classElement.getField(paramName);
    if (field != null) {
      final fieldResult = _checkAnnotations(field);
      if (fieldResult != null) {
        source = fieldResult.source;
        customName = fieldResult.name;
      }
    }

    // Check parameter annotations (override field annotations)
    final paramResult = _checkAnnotations(param);
    if (paramResult != null) {
      source = paramResult.source;
      customName = paramResult.name ?? customName;
    }

    // For complex types, source remains extra (default).
    final baseType = _getBaseType(typeStr);

    final urlName = customName ?? paramName;

    // Validate type for path/query
    if (source == 'path' || source == 'query') {
      const allowedTypes = ['String', 'int', 'double', 'bool'];
      if (!allowedTypes.contains(baseType)) {
        throw InvalidGenerationSourceError(
          'Parameter "$paramName" in ${classElement.name} has invalid type "$typeStr" for source "$source". '
          'Allowed types are: ${allowedTypes.join(', ')}.',
          element: param,
        );
      }
    }

    // Validate Query parameters must have a default value
    if (source == 'query' && !param.hasDefaultValue) {
      throw InvalidGenerationSourceError(
        'Query parameter "$paramName" in ${classElement.name} must have a default value in the constructor.',
        element: param,
      );
    }

    return _ParamData(
      name: paramName,
      urlName: urlName,
      type: typeStr,
      baseType: baseType,
      isRequired: isRequired,
      isNullable: isNullable,
      isNamed: param.isNamed,
      source: source,
      defaultValueCode: param.defaultValueCode,
      importPath: importPath,
    );
  }

  /// Checks for @Path, @Query annotations on an element.
  _AnnotationResult? _checkAnnotations(Element element) {
    // Check @Path
    if (_pathChecker.hasAnnotationOf(element)) {
      final annotation = _pathChecker.firstAnnotationOf(element);
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        final name = reader.peek('name')?.stringValue;
        return _AnnotationResult(source: 'path', name: name);
      }
    }

    // Check @Query
    if (_queryChecker.hasAnnotationOf(element)) {
      final annotation = _queryChecker.firstAnnotationOf(element);
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        final name = reader.peek('name')?.stringValue;
        return _AnnotationResult(source: 'query', name: name);
      }
    }

    return null;
  }

  /// Generates the complete output file content.
  String _generateFile(List<_BaseRouteData> allRoutes, Set<String> imports) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by tp_router_generator');
    buffer.writeln();
    buffer.writeln("import 'package:tp_router/tp_router.dart';");
    buffer.writeln("import 'package:flutter/widgets.dart';");

    // Import source files
    for (final import in imports.toList()..sort()) {
      buffer.writeln("import '$import';");
    }
    buffer.writeln();

    // Generate Route classes
    for (final route in allRoutes) {
      if (route is _RouteData) {
        buffer.writeln(_generateRouteClass(route, allRoutes));
      } else if (route is _ShellRouteData) {
        buffer.writeln(_generateShellRouteClass(route, allRoutes));
      }
    }

    // Generate tpRoutes list (Tree Structure)
    buffer.writeln('/// All generated routes in the application.');
    buffer.writeln('///');
    buffer.writeln('/// Use this list to initialize [TpRouter]:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// final router = TpRouter(routes: tpRoutes);');
    buffer.writeln('/// ```');
    buffer.writeln('List<TpRouteBase> get tpRoutes => [');

    // Find child routes (routes with navigatorKey) to exclude from root list
    final childRouteClassNames = <String>{};
    for (final route in allRoutes) {
      if (route is _RouteData && route.parentNavigatorKey != null) {
        childRouteClassNames.add(route.className);
      } else if (route is _ShellRouteData && route.parentNavigatorKey != null) {
        childRouteClassNames.add(route.className);
      }
    }

    // Generate root routes (shells and routes without navigatorKey)
    for (final route in allRoutes) {
      if (!childRouteClassNames.contains(route.className)) {
        buffer.writeln('      ${route.routeClassName}.routeInfo,');
      }
    }
    buffer.writeln('    ];');

    return buffer.toString();
  }

  /// Groups child routes by navigatorKey and branchIndex.
  Map<int, List<_BaseRouteData>> _groupChildRoutesByBranch(
    String navigatorKey,
    List<_BaseRouteData> allRoutes,
  ) {
    final branches = <int, List<_BaseRouteData>>{};
    for (final route in allRoutes) {
      if (route is _RouteData && route.parentNavigatorKey == navigatorKey) {
        branches.putIfAbsent(route.branchIndex, () => []).add(route);
      } else if (route is _ShellRouteData &&
          route.parentNavigatorKey == navigatorKey) {
        branches.putIfAbsent(route.branchIndex, () => []).add(route);
      }
    }
    return branches;
  }

  String? _findShellRouteGlobalKey(
    String? parentKey,
    List<_BaseRouteData> allRoutes,
  ) {
    if (parentKey == null) return null;
    for (final route in allRoutes) {
      if (route is _ShellRouteData && route.navigatorKey == parentKey) {
        return '${route.routeClassName}.navigatorGlobalKey';
      }
    }
    return null; // Or throw error? For now, null means no parent found (or user provided weird key)
  }

  String _generateShellRouteClass(
    _ShellRouteData route,
    List<_BaseRouteData> allRoutes,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('class ${route.routeClassName} {');

    // Generate static navigatorKey constant and GlobalKey
    if (!route.isIndexedStack) {
      buffer.writeln(
        "  static final navigatorGlobalKey = GlobalKey<NavigatorState>(debugLabel: '${route.navigatorKey}');",
      );
      buffer.writeln(
        "  static const navigatorKey = '${route.navigatorKey}';",
      );
    }
    buffer.writeln();

    // Find child routes by navigatorKey
    final branchesMap =
        _groupChildRoutesByBranch(route.navigatorKey, allRoutes);
    final sortedBranchIndices = branchesMap.keys.toList()..sort();

    if (route.isIndexedStack) {
      // Generate GlobalKey for each branch
      for (int i = 0; i < sortedBranchIndices.length; i++) {
        buffer.writeln(
          "  static final _branchKey$i = GlobalKey<NavigatorState>(debugLabel: '${route.navigatorKey}_branch_$i');",
        );
      }
      buffer.writeln();

      // Generate TpStatefulShellRouteInfo
      buffer.writeln(
        '  static final TpStatefulShellRouteInfo routeInfo = TpStatefulShellRouteInfo(',
      );
      // For stateful shell, the builder receives navigationShell
      buffer.writeln(
        '    builder: (context, navigationShell) => ${route.className}(navigationShell: navigationShell),',
      );
      buffer.writeln('    branches: [');
      for (final branchIndex in sortedBranchIndices) {
        final branchRoutes = branchesMap[branchIndex]!;
        buffer.writeln('      [');
        for (final childRoute in branchRoutes) {
          buffer.writeln('        ${childRoute.routeClassName}.routeInfo,');
        }
        buffer.writeln('      ],');
      }
      buffer.writeln('    ],');
      // Pass branch navigator keys
      buffer.write('    branchNavigatorKeys: [');
      for (int i = 0; i < sortedBranchIndices.length; i++) {
        buffer.write('_branchKey$i, ');
      }
      buffer.writeln('],');

      // Generate observersBuilder
      if (route.observers.isNotEmpty) {
        buffer.writeln('    observersBuilder: () => [');
        for (final observer in route.observers) {
          buffer.writeln('      $observer(),');
        }
        buffer.writeln('    ],');
      }

      // Generate parentNavigatorKey
      /*
      final parentKeyRef =
          _findShellRouteGlobalKey(route.parentNavigatorKey, allRoutes);
      if (parentKeyRef != null) {
        buffer.writeln('    parentNavigatorKey: $parentKeyRef,');
      }
      */

      // Generate page config
      if (route.fullscreenDialog) buffer.writeln('    fullscreenDialog: true,');
      if (route.opaque) buffer.writeln('    opaque: true,');
      if (route.barrierDismissible)
        buffer.writeln('    barrierDismissible: true,');
      if (route.barrierColor != null)
        buffer.writeln('    barrierColor: Color(${route.barrierColor}),');
      if (route.barrierLabel != null)
        buffer.writeln("    barrierLabel: '${route.barrierLabel}',");
      if (!route.maintainState) buffer.writeln('    maintainState: false,');
      if (route.transitionType != null) {
        buffer.writeln('    transition: ${route.transitionType},');
      }
      if (route.transitionDuration != Duration.zero) {
        buffer.writeln(
            '    transitionDuration: const Duration(microseconds: ${route.transitionDuration.inMicroseconds}),');
      }
      if (route.reverseTransitionDuration != Duration.zero) {
        buffer.writeln(
            '    reverseTransitionDuration: const Duration(microseconds: ${route.reverseTransitionDuration.inMicroseconds}),');
      }

      buffer.writeln('  );');
    } else {
      // Original Stateless ShellRoute
      buffer.writeln(
        '  static final TpShellRouteInfo routeInfo = TpShellRouteInfo(',
      );
      buffer.writeln(
        '    builder: (context, child) => ${route.className}(child: child),',
      );
      buffer.writeln('    navigatorKey: navigatorGlobalKey,');
      buffer.writeln('    routes: [');
      // For regular shell, all child routes go into a flat list
      for (final branchIndex in sortedBranchIndices) {
        final branchRoutes = branchesMap[branchIndex]!;
        for (final childRoute in branchRoutes) {
          buffer.writeln('      ${childRoute.routeClassName}.routeInfo,');
        }
      }
      buffer.writeln('    ],');
      // Generate observers
      if (route.observers.isNotEmpty) {
        buffer.writeln('    observers: [');
        for (final observer in route.observers) {
          buffer.writeln('      $observer(),');
        }
        buffer.writeln('    ],');
      }
      // Generate page config
      if (route.fullscreenDialog) buffer.writeln('    fullscreenDialog: true,');
      if (route.opaque) buffer.writeln('    opaque: true,');
      if (route.barrierDismissible)
        buffer.writeln('    barrierDismissible: true,');
      if (route.barrierColor != null)
        buffer.writeln('    barrierColor: Color(${route.barrierColor}),');
      if (route.barrierLabel != null)
        buffer.writeln("    barrierLabel: '${route.barrierLabel}',");
      if (!route.maintainState) buffer.writeln('    maintainState: false,');
      if (route.transitionType != null) {
        buffer.writeln('    transition: ${route.transitionType},');
      }
      if (route.transitionDuration != Duration.zero) {
        buffer.writeln(
            '    transitionDuration: const Duration(microseconds: ${route.transitionDuration.inMicroseconds}),');
      }
      if (route.reverseTransitionDuration != Duration.zero) {
        buffer.writeln(
            '    reverseTransitionDuration: const Duration(microseconds: ${route.reverseTransitionDuration.inMicroseconds}),');
      }

      // Generate parentNavigatorKey
      /*
      // For StatefulShellRoute, parentNavigatorKey usually points to nothing valid
      // because StatefulShells use branch keys. So we must rely on implicit nesting.
      final parentKeyRef =
          _findShellRouteGlobalKey(route.parentNavigatorKey, allRoutes);
      if (parentKeyRef != null) {
        buffer.writeln('    parentNavigatorKey: $parentKeyRef,');
      }
      */
      buffer.writeln('  );');
    }

    buffer.writeln('}');
    buffer.writeln();
    return buffer.toString();
  }

  /// Generates a Route class for navigation.
  String _generateRouteClass(
    _RouteData route,
    List<_BaseRouteData> allRoutes,
  ) {
    final buffer = StringBuffer();
    final routeClassName = route.routeClassName;

    buffer.writeln('/// Route class for [${route.className}].');
    buffer.writeln('///');
    buffer.writeln('/// Usage:');
    buffer.writeln('/// ```dart');
    if (route.params.isEmpty) {
      buffer.writeln('/// $routeClassName().tp(context);');
    } else {
      final exampleArgs = route.params
          .where((p) => p.isRequired)
          .map((p) => '${p.name}: ${_getExampleValue(p)}')
          .join(', ');
      buffer.writeln('/// $routeClassName($exampleArgs).tp(context);');
    }
    buffer.writeln('/// ```');
    buffer.writeln('class $routeClassName extends TpRouteData {');

    // Fields
    for (final param in route.params) {
      buffer.writeln('  final ${param.type} ${param.name};');
    }
    if (route.params.isNotEmpty) {
      buffer.writeln();
    }

    // Constructor
    buffer.write('  const $routeClassName(');
    if (route.params.isNotEmpty) {
      buffer.writeln('{');
      for (final param in route.params) {
        if (param.isRequired) {
          buffer.writeln('    required this.${param.name},');
        } else {
          if (param.defaultValueCode != null) {
            buffer.writeln(
              '    this.${param.name} = ${param.defaultValueCode},',
            );
          } else {
            buffer.writeln('    this.${param.name},');
          }
        }
      }
      buffer.write('  }');
    }
    buffer.writeln(');');
    buffer.writeln();

    // Path getter
    buffer.writeln('  /// The route path.');
    buffer.writeln("  static const String path = '${route.path}';");
    buffer.writeln();

    // Static routeInfo (inline TpRouteInfo)
    buffer.writeln('  /// The route info for this route.');
    buffer.writeln('  static final TpRouteInfo routeInfo = TpRouteInfo(');
    buffer.writeln("    path: '${route.path}',");
    if (route.name != null) {
      buffer.writeln("    name: '${route.name}',");
    }
    buffer.writeln('    isInitial: ${route.isInitial},');
    // Generate parentNavigatorKey
    // Generate parentNavigatorKey
    /*
    final parentKeyRef =
        _findShellRouteGlobalKey(route.parentNavigatorKey, allRoutes);
    if (parentKeyRef != null) {
      buffer.writeln('    parentNavigatorKey: $parentKeyRef,');
    }
    */

    if (route.onExit != null) {
      buffer.writeln('    onExit: ${route.onExit},');
    }

    if (route.fullscreenDialog) {
      buffer.writeln('    fullscreenDialog: true,');
    }
    if (!route.opaque) {
      buffer.writeln('    opaque: false,');
    }
    if (route.barrierDismissible) {
      buffer.writeln('    barrierDismissible: true,');
    }
    if (route.barrierColor != null) {
      buffer.writeln('    barrierColor: Color(${route.barrierColor}),');
    }
    if (route.barrierLabel != null) {
      buffer.writeln("    barrierLabel: '${route.barrierLabel}',");
    }
    if (!route.maintainState) {
      buffer.writeln('    maintainState: false,');
    }
    buffer.write('    params: [');
    if (route.params.isEmpty) {
      buffer.writeln('],');
    } else {
      buffer.writeln();
      for (final param in route.params) {
        buffer.writeln('      TpParamInfo(');
        buffer.writeln("        name: '${param.name}',");
        buffer.writeln("        urlName: '${param.urlName}',");
        buffer.writeln("        type: '${param.type}',");
        buffer.writeln('        isRequired: ${param.isRequired},');
        buffer.writeln("        source: '${param.source}',");
        buffer.writeln('      ),');
      }
      buffer.writeln('    ],');
    }
    if (route.redirect != null) {
      buffer.writeln(
          '    redirect: (context, ${route.params.isEmpty ? '_' : 'state'}) async {');

      if (route.params.isNotEmpty) {
        buffer.writeln('      final settings = state;');
        for (final param in route.params) {
          buffer.writeln(_generateParamExtraction(param));
        }
      }

      // Instantiate route
      buffer.write('      final route = ${route.routeClassName}(');
      final constructorArgs = <String>[];
      for (final p in route.params) {
        if (p.isNamed) {
          if (!p.isRequired && p.defaultValueCode != null) {
            constructorArgs.add(
              '${p.name}: (${p.name} ?? ${p.defaultValueCode})',
            );
          } else {
            constructorArgs.add('${p.name}: ${p.name}');
          }
        } else {
          if (!p.isRequired && p.defaultValueCode != null) {
            constructorArgs.add('(${p.name} ?? ${p.defaultValueCode})');
          } else {
            constructorArgs.add(p.name);
          }
        }
      }
      buffer.writeln('${constructorArgs.join(', ')});');

      if (route.redirect!.isClass) {
        buffer.writeln(
          '      return const ${route.redirect!.name}().handle(context, route);',
        );
      } else {
        buffer.writeln('      return ${route.redirect!.name}(context, route);');
      }
      buffer.writeln('    },');
    }
    buffer.writeln('    builder: (settings) {');
    // Generate parameter extraction
    for (final param in route.params) {
      buffer.writeln(_generateParamExtraction(param));
    }
    // Generate constructor call
    buffer.write('      return ${route.className}(');
    final constructorArgs = <String>[];
    for (final p in route.params) {
      if (p.isNamed) {
        if (!p.isRequired && p.defaultValueCode != null) {
          constructorArgs.add(
            '${p.name}: (${p.name} ?? ${p.defaultValueCode})',
          );
        } else {
          constructorArgs.add('${p.name}: ${p.name}');
        }
      } else {
        if (!p.isRequired && p.defaultValueCode != null) {
          constructorArgs.add('(${p.name} ?? ${p.defaultValueCode})');
        } else {
          constructorArgs.add(p.name);
        }
      }
    }
    buffer.writeln('${constructorArgs.join(', ')});');
    buffer.writeln('    },');

    // Add transition parameters if specified
    if (route.transitionType != null) {
      buffer.writeln('    transition: const ${route.transitionType}(),');
      buffer.writeln(
        '    transitionDuration: const Duration(microseconds: ${route.transitionDuration.inMicroseconds}),',
      );
      buffer.writeln(
        '    reverseTransitionDuration: const Duration(microseconds: ${route.reverseTransitionDuration.inMicroseconds}),',
      );
    }

    buffer.writeln('  );');
    buffer.writeln();

    // Build path method
    buffer.writeln('  @override');
    buffer.writeln('  String get fullPath {');
    buffer.writeln("    var p = '${route.path}';");

    // Replace path parameters
    final pathParams = route.params.where((p) => p.source == 'path');
    for (final param in pathParams) {
      buffer.writeln(
        "    p = p.replaceAll(':${param.urlName}', ${param.name}.toString());",
      );
    }

    // Build query parameters
    final queryParams = route.params.where(
      (p) =>
          p.source == 'query' ||
          (p.source == 'auto' && !_isComplexType(p.baseType)),
    );
    if (queryParams.isNotEmpty) {
      buffer.writeln('    final queryParts = <String>[];');
      for (final param in queryParams) {
        if (param.isNullable) {
          buffer.writeln(
            "    if (${param.name} != null) queryParts.add('${param.urlName}=\${Uri.encodeComponent(${param.name}.toString())}');",
          );
        } else {
          buffer.writeln(
            "    queryParts.add('${param.urlName}=\${Uri.encodeComponent(${param.name}.toString())}');",
          );
        }
      }
      buffer.writeln(
        "    if (queryParts.isNotEmpty) p = '\$p?\${queryParts.join('&')}';",
      );
    }

    buffer.writeln('    return p;');
    buffer.writeln('  }');
    buffer.writeln();

    // Extra data getter
    final extraParams = route.params.where((p) => p.source == 'extra');
    if (extraParams.isNotEmpty) {
      buffer.writeln('  @override');
      buffer.writeln('  Map<String, dynamic> get extra => {');
      for (final param in extraParams) {
        buffer.writeln("    '${param.urlName}': ${param.name},");
      }
      buffer.writeln('  };');
      buffer.writeln();
    }

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  /// Gets an example value for a parameter type.
  String _getExampleValue(_ParamData param) {
    switch (param.baseType) {
      case 'int':
        return '123';
      case 'double':
        return '1.0';
      case 'bool':
        return 'true';
      case 'String':
        return "'value'";
      default:
        return 'value';
    }
  }

  /// Generates extraction code for a single parameter.
  String _generateParamExtraction(_ParamData p) {
    final name = p.name;
    final urlName = p.urlName;
    final isRequired = p.isRequired;

    // Determine the source access method for string-based parameters
    String stringSourceAccess;
    switch (p.source) {
      case 'path':
        stringSourceAccess = "settings.pathParams['$urlName']";
        break;
      case 'query':
        stringSourceAccess = "settings.queryParams['$urlName']";
        break;
      default:
        // Default (extra) fallback
        stringSourceAccess =
            "settings.pathParams['$urlName'] ?? settings.queryParams['$urlName']";
    }

    // Identify if we should check settings.extra for this parameter
    // User logic: checkExtra if not path and not query
    final checkExtra = p.source != 'path' && p.source != 'query';

    // Helper to generate the extra check block
    String generateExtraCheck(String type) {
      if (!checkExtra) return '';
      return '''
      final extraValue = settings.extra['$urlName'];
      if (extraValue is $type) {
        return extraValue;
      }
''';
    }

    // Generates the parsing logic closure
    String generateParsingLogic(
      String type,
      String parseMethod, {
      bool isBool = false,
    }) {
      final extraCheck = generateExtraCheck(type);
      return '''      final $name = (() {
${extraCheck.isNotEmpty ? '$extraCheck\n' : ''}        final raw = $stringSourceAccess;
        if (raw == null) {
          ${isRequired ? "throw ArgumentError('Missing required parameter: $name');" : "return null;"}
        }
        ${isBool ? '''final lower = raw.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true;
        if (lower == 'false' || lower == '0' || lower == 'no') return false;
        ${isRequired ? "throw ArgumentError('Invalid bool value for: $name');" : "return null;"}''' : '''final parsed = $parseMethod(raw);
        if (parsed == null) {
          ${isRequired ? "throw ArgumentError('Invalid $type value for: $name');" : "return null;"}
        }
        return parsed;'''}
      })();''';
    }

    // Generate type-specific extraction
    switch (p.baseType) {
      case 'int':
        return generateParsingLogic('int', 'int.tryParse');

      case 'double':
        return generateParsingLogic('double', 'double.tryParse');

      case 'bool':
        return generateParsingLogic('bool', '', isBool: true);

      case 'num':
        return generateParsingLogic('num', 'num.tryParse');

      case 'String':
      default:
        // Complex types strictly use extra extraction (with check)
        if (_isComplexType(p.baseType)) {
          return _generateExtraExtraction(p);
        }

        // String case: check extra (if typed String), then fallback string source
        if (checkExtra) {
          return '''      final $name = (() {
        final extraValue = settings.extra['$urlName'];
        if (extraValue is String) {
          return extraValue;
        }
        return $stringSourceAccess ?? ${isRequired ? "(throw ArgumentError('Missing required parameter: $name'))" : "null"};
      })();''';
        }

        // Path/Query String case (source is 'path' or 'query')
        if (isRequired) {
          return '''      final $name = ($stringSourceAccess ??
          (throw ArgumentError('Missing required parameter: $name')));''';
        } else {
          return '''      final $name = $stringSourceAccess;''';
        }
    }
  }

  /// Generates extraction for complex types from extra.
  String _generateExtraExtraction(_ParamData p) {
    final name = p.name;
    final urlName = p.urlName;
    final type = p.type;
    final isRequired = p.isRequired;

    return '''      final $name = (() {
        final extra = settings.extra;
        if (extra.containsKey('$urlName')) {
          return extra['$urlName'] as $type;
        }
        if (extra is ${p.baseType}) {
          return extra as $type;
        }
        ${isRequired ? "throw ArgumentError('Missing required parameter: $name');" : "return null;"}
      })();''';
  }

  /// Gets the base type without nullability suffix.
  String _getBaseType(String type) {
    if (type.endsWith('?')) {
      return type.substring(0, type.length - 1);
    }
    return type;
  }

  /// Checks if a type is complex (not a primitive).
  bool _isComplexType(String type) {
    const primitives = ['String', 'int', 'double', 'bool', 'num'];
    return !primitives.contains(type);
  }
}

/// Result of checking annotations.
class _AnnotationResult {
  final String source;
  final String? name;

  _AnnotationResult({required this.source, this.name});
}

class RedirectInfo {
  final String name;
  final String? importPath;
  final bool isClass;

  RedirectInfo({required this.name, this.importPath, this.isClass = false});
}

/// Base data for any route.
abstract class _BaseRouteData {
  String get className;
  String get routeClassName;
}

/// Data for a standard route.
class _RouteData implements _BaseRouteData {
  @override
  final String className;
  @override
  final String routeClassName;
  final String path;
  final String? name;
  final bool isInitial;
  final List<_ParamData> params;
  final RedirectInfo? redirect;
  final String? transitionType;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final String? parentNavigatorKey;
  final int branchIndex;
  final String? onExit;
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final int? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final Set<String> extraImports;

  _RouteData({
    required this.className,
    required this.routeClassName,
    required this.path,
    required this.name,
    required this.isInitial,
    required this.params,
    this.redirect,
    this.transitionType,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.parentNavigatorKey,
    this.branchIndex = 0,
    this.onExit,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.extraImports = const {},
  });
}

/// Data for a shell route.
class _ShellRouteData implements _BaseRouteData {
  @override
  final String className;
  @override
  final String routeClassName;
  final String navigatorKey;
  final String? parentNavigatorKey;
  final int branchIndex;
  final bool isIndexedStack;
  final List<String> observers;

  final Set<String> extraImports;
  final bool fullscreenDialog;
  final bool opaque;
  final bool barrierDismissible;
  final int? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final String? transitionType;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  _ShellRouteData({
    required this.className,
    required this.routeClassName,
    required this.navigatorKey,
    this.parentNavigatorKey,
    this.branchIndex = 0,
    required this.isIndexedStack,
    this.observers = const [],
    this.extraImports = const {},
    this.fullscreenDialog = false,
    this.opaque = false,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.transitionType,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  });
}

/// Data for a parameter.
class _ParamData {
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

  _ParamData({
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
