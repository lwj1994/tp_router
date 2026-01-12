import 'package:test/test.dart';
import 'package:teleport_router_generator/src/models/route_data.dart';
import 'package:teleport_router_generator/src/writers/route_writer.dart';

void main() {
  group('fromData generation', () {
    late RouteWriter writer;

    setUp(() {
      writer = RouteWriter();
    });

    test('generates compact fromData for routes without parameters', () {
      final route = RouteData(
        className: 'HomePage',
        routeClassName: 'HomeRoute',
        path: '/home',
        originalPath: '/home',
        isInitial: true,
        params: [], // No parameters
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      // Should not have "final settings = data;" line
      expect(output, isNot(contains('    final settings = data;')));

      // Should have compact single-line return
      expect(output, contains('return HomeRoute();'));

      // Should not have multi-line constructor format
      expect(output, isNot(contains(RegExp(r'return HomeRoute\(\s+\);'))));
    });

    test('generates full fromData for routes with parameters', () {
      final route = RouteData(
        className: 'UserPage',
        routeClassName: 'UserRoute',
        path: '/user/:id',
        originalPath: '/user/:id',
        isInitial: false,
        params: [
          ParamData(
            name: 'id',
            urlName: 'id',
            type: 'int',
            baseType: 'int',
            isRequired: true,
            isNullable: false,
            isNamed: true,
            source: 'path',
          ),
        ],
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      // Should have settings variable for parameter extraction
      expect(output, contains('    final settings = data;'));

      // Should have parameter extraction logic
      expect(output, contains('pathParams[\'id\']'));

      // Should have multi-line constructor format
      expect(output, contains('return UserRoute('));
      expect(output, contains('id: id'));
    });

    test('generates compact fromData for routes with only optional parameters',
        () {
      final route = RouteData(
        className: 'SearchPage',
        routeClassName: 'SearchRoute',
        path: '/search',
        originalPath: '/search',
        isInitial: false,
        params: [
          ParamData(
            name: 'query',
            urlName: 'query',
            type: 'String?',
            baseType: 'String',
            isRequired: false,
            isNullable: true,
            isNamed: true,
            source: 'query',
          ),
        ],
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      // Should have settings variable even for optional parameters
      expect(output, contains('    final settings = data;'));

      // Should have parameter extraction
      expect(output, contains('queryParams[\'query\']'));

      // Should have multi-line format
      expect(output, contains('return SearchRoute('));
    });

    test('formats single-line return correctly', () {
      final route = RouteData(
        className: 'AboutPage',
        routeClassName: 'AboutRoute',
        path: '/about',
        originalPath: '/about',
        isInitial: false,
        params: [],
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      // Extract the fromData method
      final fromDataMatch = RegExp(
        r'static AboutRoute fromData\(TeleportRouteData data\) \{[^}]+\}',
        multiLine: true,
        dotAll: true,
      ).firstMatch(output);

      expect(fromDataMatch, isNotNull);

      final fromDataMethod = fromDataMatch!.group(0)!;

      // Should have exactly 4 lines (method signature, type check, return, closing brace)
      final lines =
          fromDataMethod.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines.length, equals(4));

      // Verify format
      expect(lines[0].trim(), startsWith('static AboutRoute fromData'));
      expect(lines[1].trim(), equals('if (data is AboutRoute) return data;'));
      expect(lines[2].trim(), equals('return AboutRoute();'));
      expect(lines[3].trim(), equals('}'));
    });

    test('formats multi-line return correctly for routes with parameters', () {
      final route = RouteData(
        className: 'ProfilePage',
        routeClassName: 'ProfileRoute',
        path: '/profile/:userId',
        originalPath: '/profile/:userId',
        isInitial: false,
        params: [
          ParamData(
            name: 'userId',
            urlName: 'userId',
            type: 'String',
            baseType: 'String',
            isRequired: true,
            isNullable: false,
            isNamed: true,
            source: 'path',
          ),
          ParamData(
            name: 'tab',
            urlName: 'tab',
            type: 'String?',
            baseType: 'String',
            isRequired: false,
            isNullable: true,
            isNamed: true,
            source: 'query',
          ),
        ],
      );

      final allRoutes = [route];
      final output = writer.generateFile(allRoutes, {});

      // Should have multi-line format with proper indentation
      expect(output, contains('return ProfileRoute('));
      expect(output, contains('      userId: userId,'));
      expect(output, contains('      tab: tab'));
      expect(output, contains('    );'));
    });
  });
}
