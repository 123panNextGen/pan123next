import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';

class AppSession extends GetxController {
  late final Rx<Brightness> theme;
  late final Rx<AccentColor> accentColor;
  final Rx<Locale> appLocale = const Locale('zh', 'CN').obs;

  @override
  void onInit() {
    super.onInit();
    final appDb = Get.find<AppDb>();
    theme = (appDb.getValue('theme') == 'dark'
        ? Brightness.dark
        : Brightness.light)
        .obs;
    accentColor = appDb.getAccentColor().obs;

    final savedLocale = Get.find<UserDb>().getValue('set.language') as String?;
    if (savedLocale != null && savedLocale.isNotEmpty) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        appLocale.value = Locale(parts[0], parts[1]);
      }
    }
    Get.locale = appLocale.value;
  }

  void updateTheme(Brightness value) {
    theme.value = value;
    Get.find<AppDb>().setValue(
      'theme',
      value == Brightness.dark ? 'dark' : 'light',
      'string',
    );
  }

  void updateAccentColor(String value) {
    Get.find<AppDb>().setValue('accentColor', value, 'string');
    accentColor.value = Get.find<AppDb>().getAccentColor();
  }

  void updateLocale(String languageTag) {
    final parts = languageTag.split('_');
    final locale = Locale(parts[0], parts[1]);
    appLocale.value = locale;
    Get.locale = locale;
    Get.find<UserDb>().setValue('set.language', languageTag, 'string');
  }

  String getTheme() => theme.value == Brightness.dark ? 'dark' : 'light';

  String getAccentColor() => accentColors.firstWhere(
    (e) => e['result'] == accentColor.value,
    orElse: () => accentColors.first,
  )['value'];

  void clearSession() {
    final userDb = Get.find<UserDb>();
    userDb.setValue('password', '', 'string');
    userDb.setValue('authorization', '', 'string');
    userDb.setValue('uuid', '', 'string');
    userDb.setValue('autoLogin', false, 'bool');
    userDb.setValue('rememberPassword', false, 'bool');
  }
}
