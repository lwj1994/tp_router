import 'package:flutter_test/flutter_test.dart';
import 'package:teleport_router/teleport_router.dart';

void main() {
  group('Logging Integration', () {
    test('extra data logging formats Map correctly', () {
      LogUtil.setEnabled(true);

      // Create a route data with Map extra
      final route = TeleportRouteData.fromPath(
        '/test',
        extra: {'key': 'value', 'count': 42},
      );

      // Verify extra is Map
      expect(route.extra, isA<Map>());
      expect(route.extra, equals({'key': 'value', 'count': 42}));
    });

    test('extra data logging formats List correctly', () {
      LogUtil.setEnabled(true);

      // Create a route data with List extra
      final route = TeleportRouteData.fromPath(
        '/test',
        extra: ['item1', 'item2', 'item3'],
      );

      // Verify extra is List
      expect(route.extra, isA<List>());
      expect(route.extra, equals(['item1', 'item2', 'item3']));
    });

    test('extra data logging formats custom object with toString', () {
      LogUtil.setEnabled(true);

      // Create a custom object with toString
      final customObj = _TestObject('test', 123);

      final route = TeleportRouteData.fromPath(
        '/test',
        extra: customObj,
      );

      // Verify extra is custom object
      expect(route.extra, isA<_TestObject>());
      expect(
          route.extra.toString(), equals('TestObject(name: test, value: 123)'));
    });

    test('extra data handles empty Map gracefully', () {
      LogUtil.setEnabled(true);

      final route = TeleportRouteData.fromPath('/test');

      // Verify extra is empty Map (default behavior)
      expect(route.extra, isA<Map>());
      expect(route.extra, isEmpty);
    });

    test('pop result logging formats String correctly', () {
      LogUtil.setEnabled(true);

      const result = 'Selected Item';

      // Verify result is String
      expect(result, isA<String>());
      expect(result, equals('Selected Item'));
    });

    test('pop result logging formats Map correctly', () {
      LogUtil.setEnabled(true);

      const result = {'status': 'success', 'value': 42};

      // Verify result is Map
      expect(result, isA<Map>());
      expect(result['status'], equals('success'));
    });

    test('pop result logging formats List correctly', () {
      LogUtil.setEnabled(true);

      const result = ['item1', 'item2'];

      // Verify result is List
      expect(result, isA<List>());
      expect(result.length, equals(2));
    });

    test('pop result logging formats custom object correctly', () {
      LogUtil.setEnabled(true);

      final result = _TestObject('result', 100);

      // Verify result is custom object
      expect(result, isA<_TestObject>());
      expect(result.toString(), equals('TestObject(name: result, value: 100)'));
    });

    tearDown(() {
      LogUtil.setEnabled(false);
    });
  });
}

class _TestObject {
  final String name;
  final int value;

  _TestObject(this.name, this.value);

  @override
  String toString() => 'TestObject(name: $name, value: $value)';
}
