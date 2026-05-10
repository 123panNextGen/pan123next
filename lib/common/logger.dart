import 'package:fluent_ui/fluent_ui.dart';

enum LoggerLevel { log, info, warning, error, debug }

class LoggerItemModel {
  final String header;
  final String msg;
  final DateTime timestamp;
  final LoggerLevel level;

  LoggerItemModel(this.header, this.msg, this.timestamp, this.level);
}

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  final List<LoggerItemModel> _logs = [];

  void log(String msg, [String header = 'Unknown']) {
    final timestamp = DateTime.now();
    _logs.add(LoggerItemModel(header, msg, timestamp, LoggerLevel.log));
    debugPrint('[LOG][$timestamp] $header: $msg');
  }

  void info(String msg, [String header = 'Unknown']) {
    final timestamp = DateTime.now();
    _logs.add(LoggerItemModel(header, msg, timestamp, LoggerLevel.info));
    debugPrint('[INFO][$timestamp] $header: $msg');
  }

  void warning(String msg, [String header = 'Unknown']) {
    final timestamp = DateTime.now();
    _logs.add(LoggerItemModel(header, msg, timestamp, LoggerLevel.warning));
    debugPrint('[WARN][$timestamp] $header: $msg');
  }

  void error(String msg, [String header = 'Unknown']) {
    final timestamp = DateTime.now();
    _logs.add(LoggerItemModel(header, msg, timestamp, LoggerLevel.error));
    debugPrint('[ERROR][$timestamp] $header: $msg');
  }

  void debug(String msg, [String header = 'Unknown']) {
    final timestamp = DateTime.now();
    final logItem = LoggerItemModel(header, msg, timestamp, LoggerLevel.debug);
    _logs.add(logItem);
    debugPrint('[DEBUG][$timestamp] $header: $msg');
  }

  List<LoggerItemModel> get logs => List.unmodifiable(_logs);
}
