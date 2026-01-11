import 'package:test/test.dart';
import 'package:teleport_router_generator/src/teleport_route_generator.dart';

void main() {
  group('TeleportRouterBuilder', () {
    late TeleportRouterBuilder builder;

    setUp(() {
      builder = TeleportRouterBuilder();
    });

    test('buildExtensions returns correct output path', () {
      expect(
        builder.buildExtensions,
        equals({
          r'lib/$lib$': ['lib/teleport_router.gr.dart'],
        }),
      );
    });
  });

  group('Route class name generation', () {
    test('removes Page suffix', () {
      expect(_testGenerateRouteClassName('HomePage'), 'HomeRoute');
      expect(
        _testGenerateRouteClassName('UserDetailsPage'),
        'UserDetailsRoute',
      );
    });

    test('removes Screen suffix', () {
      expect(_testGenerateRouteClassName('LoginScreen'), 'LoginRoute');
      expect(_testGenerateRouteClassName('ProfileScreen'), 'ProfileRoute');
    });

    test('handles class without Page/Screen suffix', () {
      expect(_testGenerateRouteClassName('Dashboard'), 'DashboardRoute');
      expect(_testGenerateRouteClassName('Settings'), 'SettingsRoute');
    });
  });

  group('Type detection', () {
    test('identifies primitive types as non-complex', () {
      expect(_testIsComplexType('String'), false);
      expect(_testIsComplexType('int'), false);
      expect(_testIsComplexType('double'), false);
      expect(_testIsComplexType('bool'), false);
      expect(_testIsComplexType('num'), false);
    });

    test('identifies custom types as complex', () {
      expect(_testIsComplexType('User'), true);
      expect(_testIsComplexType('List'), true);
      expect(_testIsComplexType('Map'), true);
      expect(_testIsComplexType('MyCustomClass'), true);
    });
  });

  group('Base type extraction', () {
    test('removes nullable suffix', () {
      expect(_testGetBaseType('String?'), 'String');
      expect(_testGetBaseType('int?'), 'int');
      expect(_testGetBaseType('User?'), 'User');
    });

    test('handles non-nullable types', () {
      expect(_testGetBaseType('String'), 'String');
      expect(_testGetBaseType('int'), 'int');
      expect(_testGetBaseType('User'), 'User');
    });
  });

  group('Example value generation', () {
    test('returns correct example values for primitive types', () {
      expect(_testGetExampleValue('int'), '123');
      expect(_testGetExampleValue('double'), '1.0');
      expect(_testGetExampleValue('bool'), 'true');
      expect(_testGetExampleValue('String'), "'value'");
    });

    test('returns generic value for complex types', () {
      expect(_testGetExampleValue('User'), 'value');
      expect(_testGetExampleValue('Map'), 'value');
    });
  });

  group('Shell Route Logic', () {
    test('finds shell global key', () {
      final routes = [
        MockShellRouteData('MainShell', 'MainRoute', null, 'main'),
        MockRouteData('Home', 'HomeRoute', 'main'),
      ];
      expect(
        _testFindShellRouteGlobalKey('main', routes),
        'MainRoute.navigatorGlobalKey',
      );
      expect(_testFindShellRouteGlobalKey('other', routes), null);
      expect(_testFindShellRouteGlobalKey(null, routes), null);
    });

    test('groups routes by branch', () {
      final routes = [
        MockRouteData('Home', 'HomeRoute', 'main', branchIndex: 0),
        MockRouteData('Settings', 'SettingsRoute', 'main', branchIndex: 1),
        MockRouteData('Detail', 'DetailRoute', 'main', branchIndex: 0),
        MockRouteData('Other', 'OtherRoute', 'other'), // Should be ignored
        MockShellRouteData('NestedShell', 'NestedRoute', 'main', 'nested',
            branchIndex: 1),
      ];

      final groups = _testGroupChildRoutesByBranch('main', routes);

      expect(groups.keys.length, 2);
      expect(groups.containsKey(0), true);
      expect(groups.containsKey(1), true);

      final branch0 = groups[0]!;
      expect(branch0.length, 2);
      expect(branch0[0].className, 'Home');
      expect(branch0[1].className, 'Detail');

      final branch1 = groups[1]!;
      expect(branch1.length, 2);
      expect(branch1[0].className, 'Settings');
      expect(branch1[1].className, 'NestedShell');
    });
  });
}

// Test helper functions and mocks

String _testGenerateRouteClassName(String className) {
  String result = className;
  if (result.endsWith('Page')) {
    result = result.substring(0, result.length - 4);
  } else if (result.endsWith('Screen')) {
    result = result.substring(0, result.length - 6);
  }
  return '${result}Route';
}

bool _testIsComplexType(String type) {
  const primitives = ['String', 'int', 'double', 'bool', 'num'];
  return !primitives.contains(type);
}

String _testGetBaseType(String type) {
  if (type.endsWith('?')) {
    return type.substring(0, type.length - 1);
  }
  return type;
}

String _testGetExampleValue(String baseType) {
  switch (baseType) {
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

// Mocks for Shell Logic Tests

abstract class MockBaseRouteData {
  final String className;
  final String routeClassName;
  final String? parentNavigatorKey;
  final int branchIndex;

  MockBaseRouteData(
      this.className, this.routeClassName, this.parentNavigatorKey,
      {this.branchIndex = 0});
}

class MockShellRouteData extends MockBaseRouteData {
  final String navigatorKey;

  MockShellRouteData(String className, String routeClassName,
      String? parentNavigatorKey, this.navigatorKey, {int branchIndex = 0})
      : super(className, routeClassName, parentNavigatorKey,
            branchIndex: branchIndex);
}

class MockRouteData extends MockBaseRouteData {
  MockRouteData(
      String className, String routeClassName, String? parentNavigatorKey,
      {int branchIndex = 0})
      : super(className, routeClassName, parentNavigatorKey,
            branchIndex: branchIndex);
}

String? _testFindShellRouteGlobalKey(
  String? parentKey,
  List<MockBaseRouteData> allRoutes,
) {
  if (parentKey == null) return null;
  for (final route in allRoutes) {
    if (route is MockShellRouteData && route.navigatorKey == parentKey) {
      return '${route.routeClassName}.navigatorGlobalKey';
    }
  }
  return null;
}

Map<int, List<MockBaseRouteData>> _testGroupChildRoutesByBranch(
  String navigatorKey,
  List<MockBaseRouteData> allRoutes,
) {
  final branches = <int, List<MockBaseRouteData>>{};
  for (final route in allRoutes) {
    if ((route is MockRouteData || route is MockShellRouteData) &&
        route.parentNavigatorKey == navigatorKey) {
      branches.putIfAbsent(route.branchIndex, () => []).add(route);
    }
  }
  return branches;
}
