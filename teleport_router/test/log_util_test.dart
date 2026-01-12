import 'package:flutter_test/flutter_test.dart';
import 'package:teleport_router/src/log_util.dart';

void main() {
  group('LogUtil', () {
    setUp(() {
      // Disable logging before each test to avoid console output
      LogUtil.setEnabled(false);
    });

    test('can be enabled and disabled', () {
      expect(LogUtil.isEnabled, isFalse);

      LogUtil.setEnabled(true);
      expect(LogUtil.isEnabled, isTrue);

      LogUtil.setEnabled(false);
      expect(LogUtil.isEnabled, isFalse);
    });

    test('logging methods do not throw when disabled', () {
      LogUtil.setEnabled(false);

      expect(() => LogUtil.debug('test'), returnsNormally);
      expect(() => LogUtil.info('test'), returnsNormally);
      expect(() => LogUtil.warning('test'), returnsNormally);
      expect(() => LogUtil.error('test'), returnsNormally);
      expect(() => LogUtil.navigation('test'), returnsNormally);
      expect(() => LogUtil.route('test'), returnsNormally);
      expect(() => LogUtil.params('test'), returnsNormally);
      expect(() => LogUtil.breadcrumb('test'), returnsNormally);
      expect(() => LogUtil.divider(), returnsNormally);
      expect(() => LogUtil.section('test'), returnsNormally);
    });

    test('logging methods do not throw when enabled', () {
      LogUtil.setEnabled(true);

      expect(() => LogUtil.debug('test message'), returnsNormally);
      expect(() => LogUtil.info('test message'), returnsNormally);
      expect(() => LogUtil.warning('test message'), returnsNormally);
      expect(
          () => LogUtil.error('test message',
              error: Exception('test'), stackTrace: StackTrace.current),
          returnsNormally);
      expect(() => LogUtil.navigation('test message'), returnsNormally);
      expect(() => LogUtil.route('test message'), returnsNormally);
      expect(() => LogUtil.params('test message'), returnsNormally);
      expect(() => LogUtil.breadcrumb('test message'), returnsNormally);
      expect(() => LogUtil.divider(), returnsNormally);
      expect(() => LogUtil.section('Test Section'), returnsNormally);
    });

    test('supports custom tags', () {
      LogUtil.setEnabled(true);

      expect(() => LogUtil.debug('message', tag: 'CustomTag'), returnsNormally);
      expect(() => LogUtil.info('message', tag: 'CustomTag'), returnsNormally);
      expect(
          () => LogUtil.warning('message', tag: 'CustomTag'), returnsNormally);
      expect(() => LogUtil.error('message', tag: 'CustomTag'), returnsNormally);
    });

    test('error method accepts optional error and stack trace', () {
      LogUtil.setEnabled(true);

      expect(() => LogUtil.error('message only'), returnsNormally);
      expect(() => LogUtil.error('with error', error: Exception('test')),
          returnsNormally);
      expect(
          () => LogUtil.error('with stack',
              error: Exception('test'), stackTrace: StackTrace.current),
          returnsNormally);
    });

    test('state persists across calls', () {
      LogUtil.setEnabled(true);
      expect(LogUtil.isEnabled, isTrue);

      LogUtil.debug('test');
      expect(LogUtil.isEnabled, isTrue);

      LogUtil.setEnabled(false);
      expect(LogUtil.isEnabled, isFalse);

      LogUtil.debug('test');
      expect(LogUtil.isEnabled, isFalse);
    });
  });
}
