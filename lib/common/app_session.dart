import 'package:fluent_ui/fluent_ui.dart';

class AppSession {
  static final AppSession _instance = AppSession._internal();

  factory AppSession() {
    return _instance;
  }

  AppSession._internal();

  Brightness _theme = Brightness.dark;
  AccentColor _accentColor = Colors.purple;
  Function(Brightness)? _themeChangeCallback;
  Function(AccentColor)? _accentColorChangeCallback;

  Brightness get theme => _theme;
  AccentColor get accentColor => _accentColor;

  set theme(Brightness value) {
    _theme = value;
    // 通知监听器主题变化
    _themeChangeCallback?.call(value);
  }

  set accentColor(AccentColor value) {
    _accentColor = value;
    // 通知监听器主题变化
    _accentColorChangeCallback?.call(value);
  }

  // 注册主题变化监听器
  void addThemeChangeListener(Function(Brightness) callback) {
    _themeChangeCallback = callback;
  }

  // 注册主题变化监听器
  void addAccentColorChangeListener(Function(AccentColor) callback) {
    _accentColorChangeCallback = callback;
  }

  // Method to clear session data
  void clearSession() {
    theme = Brightness.dark;
    accentColor = Colors.purple;
  }
}
