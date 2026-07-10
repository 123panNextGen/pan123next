import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';

class AppSession extends GetxController {
  late final Rx<Brightness> theme;
  late final Rx<AccentColor> accentColor;
  final Rx<Locale> appLocale = const Locale('zh', 'CN').obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    final appDb = Get.find<AppDb>();
    theme =
        (appDb.getValue('theme') == 'dark' ? Brightness.dark : Brightness.light)
            .obs;
    accentColor = appDb.getAccentColor().obs;
  }

  void updateTheme(Brightness value) {
    theme.value = value;
    Get.find<AppDb>().setValue(
      'theme',
      value == Brightness.dark ? 'dark' : 'light',
    );
    update();
  }

  void updateAccentColor(String value) {
    Get.find<AppDb>().setValue('accentColor', value);
    accentColor.value = Get.find<AppDb>().getAccentColor();
    update();
  }

  String getTheme() => theme.value == Brightness.dark ? 'dark' : 'light';

  String getAccentColor() => accentColors.firstWhere(
    (e) => e['result'] == accentColor.value,
    orElse: () => accentColors.first,
  )['value'];

  void clearSession() {
    final userDb = Get.find<UserDb>();
    userDb.setValue('password', '');
    userDb.setValue('authorization', '');
    userDb.setValue('uuid', '');
    userDb.setValue('autoLogin', false);
    userDb.setValue('rememberPassword', false);
  }
}
