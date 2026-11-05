import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static void log(
    String message, {
    String tag = 'App',
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: _toLevelInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String tag = 'App'}) =>
      log(message, tag: tag, level: LogLevel.debug);

  static void info(String message, {String tag = 'App'}) =>
      log(message, tag: tag, level: LogLevel.info);

  static void warning(String message, {String tag = 'App', Object? error}) =>
      log(message, tag: tag, level: LogLevel.warning, error: error);

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(message, tag: tag, level: LogLevel.error, error: error, stackTrace: stackTrace);

  static int _toLevelInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
