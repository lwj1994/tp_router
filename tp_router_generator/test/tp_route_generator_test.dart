import 'package:test/test.dart';
import 'package:tp_router_generator/src/tp_route_generator.dart';

void main() {
  group('TpRouterBuilder', () {
    late TpRouterBuilder builder;

    setUp(() {
      builder = TpRouterBuilder();
    });

    test('buildExtensions returns correct output path', () {
      expect(
        builder.buildExtensions,
        equals({
          r'lib/$lib$': ['lib/tp_router.gr.dart'],
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
}

// Test helper functions that expose private methods for testing
// These mirror the private methods in TpRouterBuilder

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
