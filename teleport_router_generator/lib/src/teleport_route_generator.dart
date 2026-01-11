import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'models/route_data.dart';
import 'writers/route_writer.dart';

/// Code generator that scans Dart files for teleport_router annotations and generates routing code.
///
/// This builder implements the [Builder] interface from build_runner and is responsible
/// for generating type-safe routing code based on `@TeleportRoute`, `@TeleportShellRoute`, and
/// `@TeleportStatefulShellRoute` annotations found in your Flutter application.
///
/// ## How It Works
///
/// 1. **Scans**: Searches all `.dart` files in the `lib/` directory for annotated classes
/// 2. **Analyzes**: Extracts routing configuration from annotations and constructor parameters
/// 3. **Generates**: Creates a single output file (default: `lib/teleport_router.gr.dart`) containing:
///    - Type-safe route classes (e.g., `HomeRoute`, `UserRoute`)
///    - Route configuration objects (`TeleportRouteInfo`, `TeleportShellRouteInfo`)
///    - Global route list (`teleportRoutes`)
///
/// ## Generated Code
///
/// For each `@TeleportRoute` annotated class, the builder generates a corresponding route class
/// that extends `TeleportRouteData` with type-safe parameter handling and navigation methods.
class TeleportRouterBuilder implements Builder {
  static const _teleportRouteChecker = TypeChecker.fromUrl(
    'package:teleport_router_annotation/src/teleport_route.dart#TeleportRoute',
  );
  static const _tpShellRouteChecker = TypeChecker.fromUrl(
    'package:teleport_router_annotation/src/teleport_route.dart#TeleportShellRoute',
  );
  static const _pathChecker = TypeChecker.fromUrl(
    'package:teleport_router_annotation/src/teleport_route.dart#Path',
  );
  static const _queryChecker = TypeChecker.fromUrl(
    'package:teleport_router_annotation/src/teleport_route.dart#Query',
  );

  final String output;

  TeleportRouterBuilder({this.output = 'lib/teleport_router.gr.dart'});

  @override
  Map<String, List<String>> get buildExtensions => {
        r'lib/$lib$': [output],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final allRoutes = <BaseRouteData>[];
    final imports = <String>{};

    // Find all Dart files in lib/
    await for (final input in buildStep.findAssets(Glob('lib/**/*.dart'))) {
      // Skip generated files
      if (input.path.endsWith('.g.dart')) continue;

      try {
        final library = await buildStep.resolver.libraryFor(input);
        final reader = LibraryReader(library);

        // Find all classes with @TeleportRoute annotation
        for (final annotated in reader.annotatedWith(_teleportRouteChecker)) {
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

        // Find all classes with @TeleportShellRoute annotation
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
      final content = RouteWriter().generateFile(allRoutes, imports);
      final outputId = AssetId(buildStep.inputId.package, output);
      await buildStep.writeAsString(outputId, content);
    }
  }

  void _validateDuplicatePaths(List<BaseRouteData> routes) {
    final pathMap = <String, String>{}; // Path -> RouteClassName

    for (final route in routes) {
      if (route is RouteData) {
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

  /// Analyzes a class with @TeleportRoute annotation.
  RouteData? _analyzeRoute(
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

    final isInitial = annotation.read('isInitial').boolValue;

    // Analyze constructor parameters
    final constructor = classElement.unnamedConstructor;
    if (constructor == null) return null;

    // Collect parameter info
    final params = <ParamData>[];
    for (final param in constructor.formalParameters) {
      // Skip 'key' parameter for widgets
      if (param.name == 'key') continue;

      final paramData = _analyzeParameter(param, classElement);
      if (paramData != null) {
        params.add(paramData);
      }
    }

    // Extract parentNavigatorKey as Type (optional)
    String? parentNavigatorKey;
    final parentKeyReader = annotation.peek('parentNavigatorKey');
    if (parentKeyReader != null && !parentKeyReader.isNull) {
      final parentType = parentKeyReader.objectValue.toTypeValue();
      if (parentType != null && parentType.element != null) {
        parentNavigatorKey = parentType.element!.name;
      }
    }

    final extraImports = <String>{};

    // Add import for parentNavigatorKey type
    if (parentKeyReader != null && !parentKeyReader.isNull) {
      final parentType = parentKeyReader.objectValue.toTypeValue();
      if (parentType?.element?.library?.identifier != null) {
        extraImports.add(parentType!.element!.library!.identifier);
      }
    }

    // Extract onExit
    String? onExit;
    final onExitReader = annotation.peek('onExit');
    if (onExitReader != null && !onExitReader.isNull) {
      final typeValue = onExitReader.objectValue.toTypeValue();
      if (typeValue != null && typeValue.element != null) {
        onExit = typeValue.element!.name;
        if (typeValue.element!.library != null) {
          extraImports.add(typeValue.element!.library!.identifier);
        }
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

    // Extract pageBuilder
    final pageBuilder = _extractPageBuilder(annotation);
    if (pageBuilder?.importPath != null) {
      extraImports.add(pageBuilder!.importPath!);
    }

    return RouteData(
      className: className,
      routeClassName: routeClassName,
      path: path,
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
      onExit: onExit,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
      extraImports: extraImports,
      pageBuilder: pageBuilder,
      pageType: _extractPageType(annotation),
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

  PageBuilderInfo? _extractPageBuilder(ConstantReader annotation) {
    final pbReader = annotation.peek('pageBuilder');
    if (pbReader == null || pbReader.isNull) return null;

    final pbValue = pbReader.objectValue;
    final pbType = pbValue.toTypeValue();

    if (pbType != null && pbType.element != null) {
      final element = pbType.element!;
      if (element.name == null) return null;
      return PageBuilderInfo(
        name: element.name!,
        importPath: element.library?.identifier,
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

  /// Analyzes a class with @TeleportShellRoute annotation.
  ShellRouteData? _analyzeShellRoute(
    Element element,
    ConstantReader annotation,
  ) {
    if (element is! ClassElement) return null;
    final className = element.name;
    if (className == null) return null;
    final routeClassName = _generateRouteClassName(className);

    // Extract navigatorKey as Type
    final navigatorKeyReader = annotation.read('navigatorKey');
    final navigatorKeyType = navigatorKeyReader.objectValue.toTypeValue();
    if (navigatorKeyType == null || navigatorKeyType.element == null) {
      throw InvalidGenerationSourceError(
        'navigatorKey must be a Type (e.g., MainNavKey)',
        element: element,
      );
    }
    final navigatorKeyClassName = navigatorKeyType.element!.name!;
    final navigatorKeyImport = navigatorKeyType.element!.library?.identifier;

    final extraImports = <String>{};
    if (navigatorKeyImport != null) {
      extraImports.add(navigatorKeyImport);
    }

    // Extract parentNavigatorKey as Type (optional)
    String? parentNavigatorKey;
    final parentKeyReader = annotation.peek('parentNavigatorKey');
    if (parentKeyReader != null && !parentKeyReader.isNull) {
      final parentType = parentKeyReader.objectValue.toTypeValue();
      if (parentType != null && parentType.element != null) {
        parentNavigatorKey = parentType.element!.name;
        if (parentType.element!.library?.identifier != null) {
          extraImports.add(parentType.element!.library!.identifier);
        }
      }
    }

    final isIndexedStack = annotation.read('isIndexedStack').boolValue;

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

    // Extract branchKeys
    final branchKeys = <String>[];
    final branchKeysReader = annotation.peek('branchKeys');
    if (branchKeysReader != null) {
      final list = branchKeysReader.listValue;
      for (final item in list) {
        final type = item.toTypeValue();
        if (type != null && type.element != null) {
          branchKeys.add(type.element!.name!);
          if (type.element!.library?.identifier != null) {
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

    // Extract pageBuilder
    final pageBuilder = _extractPageBuilder(annotation);
    if (pageBuilder?.importPath != null) {
      extraImports.add(pageBuilder!.importPath!);
    }

    return ShellRouteData(
      className: className,
      routeClassName: routeClassName,
      navigatorKey: navigatorKeyClassName,
      parentNavigatorKey: parentNavigatorKey,
      isIndexedStack: isIndexedStack,
      observers: observers,
      extraImports: extraImports,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
      pageBuilder: pageBuilder,
      pageType: _extractPageType(annotation),
      branchKeys: branchKeys,
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

  ParamData? _analyzeParameter(
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

    return ParamData(
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
  AnnotationResult? _checkAnnotations(Element element) {
    // Check @Path
    if (_pathChecker.hasAnnotationOf(element)) {
      final annotation = _pathChecker.firstAnnotationOf(element);
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        final name = reader.peek('name')?.stringValue;
        return AnnotationResult(source: 'path', name: name);
      }
    }

    // Check @Query
    if (_queryChecker.hasAnnotationOf(element)) {
      final annotation = _queryChecker.firstAnnotationOf(element);
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        final name = reader.peek('name')?.stringValue;
        return AnnotationResult(source: 'query', name: name);
      }
    }

    return null;
  }

  /// Gets the base type without nullability suffix.
  String _getBaseType(String type) {
    if (type.endsWith('?')) {
      return type.substring(0, type.length - 1);
    }
    return type;
  }

  /// Extracts the page type from annotation.
  String? _extractPageType(ConstantReader annotation) {
    final reader = annotation.peek('type');
    if (reader == null || reader.isNull) return null;

    final index = reader.objectValue.getField('index')?.toIntValue();
    if (index != null) {
      const types = ['auto', 'material', 'cupertino', 'swipeBack', 'custom'];
      if (index >= 0 && index < types.length) {
        return 'TeleportPageType.${types[index]}';
      }
    }
    return null;
  }
}
