import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/data/app.dart';

class AppSession extends GetxController {
  final Rx<Brightness> theme = AppDb().getValue('theme') == 'dark'
      ? Brightness.dark.obs
      : Brightness.light.obs;
  final Rx<AccentColor> accentColor = AppDb().getAccentColor().obs;

  void updateTheme(Brightness value) {
    theme.value = value;
    AppDb().setValue(
      'theme',
      value == Brightness.dark ? 'dark' : 'light',
      'string',
    );
  }

  void updateAccentColor(String value) {
    AppDb().setValue('accentColor', value, 'string');
    accentColor.value = AppDb().getAccentColor();
  }

  String getTheme() => theme.value == Brightness.dark ? 'dark' : 'light';

  String getAccentColor() => accentColors.firstWhere(
    (e) => e['result'] == accentColor.value,
    orElse: () => accentColors.first,
  )['value'];

  void clearSession() {
    updateTheme(Brightness.dark);
    updateAccentColor('purple');
  }
}
