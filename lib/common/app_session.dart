import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/data/app.dart';

class AppSession extends GetxController {
  final Rx<Brightness> theme = Brightness.dark.obs;
  final Rx<AccentColor> accentColor = Colors.purple.obs;

  static final _accentColorMap = {
    'purple': Colors.purple,
    'blue': Colors.blue,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'red': Colors.red,
  };

  void updateTheme(Brightness value) {
    theme.value = value;
    AppDb().setValue(
      'theme',
      value == Brightness.dark ? 'dark' : 'light',
      'string',
    );
  }

  void updateAccentColor(String value) {
    accentColor.value = _accentColorMap[value] ?? Colors.purple;
    AppDb().setValue('accentColor', value, 'string');
  }

  String getTheme() => theme.value == Brightness.dark ? 'dark' : 'light';

  String getAccentColor() => _accentColorMap.entries
      .firstWhere(
        (e) => e.value == accentColor.value,
        orElse: () => MapEntry('purple', Colors.purple),
      )
      .key;

  void clearSession() {
    updateTheme(Brightness.dark);
    updateAccentColor('purple');
  }
}
