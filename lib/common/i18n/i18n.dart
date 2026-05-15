import 'translations.dart';

extension I18nString on String {
  String get i => AppTranslations.zhCn[this] ?? this;
  String iParams(Map<String, String> params) {
    var text = AppTranslations.zhCn[this] ?? this;
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
}
