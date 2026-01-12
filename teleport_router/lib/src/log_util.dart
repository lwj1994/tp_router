import 'package:flutter/foundation.dart';

/// Logging utility for TeleportRouter debugging.
///
/// Provides centralized logging control that can be enabled/disabled
/// at runtime via [TeleportRouter] configuration.
///
/// Example:
/// ```dart
/// TeleportRouter(
///   enableLogging: true, // Enable debug logs
///   router: router,
/// );
/// ```
class LogUtil {
  LogUtil._();

  /// Whether logging is enabled globally
  static bool _enabled = false;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (_enabled) {
      _log('📍 TeleportRouter logging enabled');
    }
  }

  /// Check if logging is enabled
  static bool get isEnabled => _enabled;

  /// Log a debug message
  ///
  /// Only prints when logging is enabled and in debug mode.
  static void debug(String message, {String? tag}) {
    if (!_enabled) return;
    _log(_formatMessage('🔍', tag ?? 'Debug', message));
  }

  /// Log an info message
  ///
  /// Only prints when logging is enabled and in debug mode.
  static void info(String message, {String? tag}) {
    if (!_enabled) return;
    _log(_formatMessage('ℹ️', tag ?? 'Info', message));
  }

  /// Log a warning message
  ///
  /// Only prints when logging is enabled and in debug mode.
  static void warning(String message, {String? tag}) {
    if (!_enabled) return;
    _log(_formatMessage('⚠️', tag ?? 'Warning', message));
  }

  /// Log an error message
  ///
  /// Only prints when logging is enabled and in debug mode.
  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    _log(_formatMessage('❌', tag ?? 'Error', message));
    if (error != null) {
      _log('   Error: $error');
    }
    if (stackTrace != null) {
      _log('   StackTrace:\n$stackTrace');
    }
  }

  /// Log navigation events
  static void navigation(String message) {
    if (!_enabled) return;
    _log(_formatMessage('🧭', 'Navigation', message));
  }

  /// Log route matching events
  static void route(String message) {
    if (!_enabled) return;
    _log(_formatMessage('🛣️', 'Route', message));
  }

  /// Log parameter extraction events
  static void params(String message) {
    if (!_enabled) return;
    _log(_formatMessage('📝', 'Params', message));
  }

  /// Log breadcrumb events
  static void breadcrumb(String message) {
    if (!_enabled) return;
    _log(_formatMessage('🍞', 'Breadcrumb', message));
  }

  /// Format log message with icon and tag
  static String _formatMessage(String icon, String tag, String message) {
    final timestamp =
        DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
    return '$icon [$timestamp] [TeleportRouter] [$tag] $message';
  }

  /// Internal log function that only prints in debug mode
  static void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  /// Log a divider line for better readability
  static void divider() {
    if (!_enabled) return;
    _log('${'─' * 60}');
  }

  /// Log a section header
  static void section(String title) {
    if (!_enabled) return;
    divider();
    _log('📌 $title');
    divider();
  }
}
