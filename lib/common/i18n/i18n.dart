import 'package:get/get.dart' hide Response;
import 'translations.dart';

class TranslationService extends GetxController {
  static TranslationService get to => Get.find();

  final Rx<String> currentLocale = 'zh_CN'.obs;
  late Map<String, String> _strings = AppTranslations.zhCn;
  late final Map<String, Map<String, String>> _all = AppTranslations().keys;

  String translate(String key) => _strings[key] ?? key;

  void switchLocale(String locale) {
    currentLocale.value = locale;
    _strings = _all[locale] ?? AppTranslations.zhCn;
  }

  Map<String, String> get currentStrings => _strings;
}

extension I18nString on String {
  String get i => TranslationService.to.translate(this);
  String iParams(Map<String, String> params) {
    var text = TranslationService.to.translate(this);
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
}
