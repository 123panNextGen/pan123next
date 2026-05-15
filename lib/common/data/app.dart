import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/i18n/i18n.dart';
import 'package:pan123next/common/data/base_db.dart';

List<Map> get themes => [
  {'value': 'dark', 'label': 'theme.dark'.i, 'result': Brightness.dark},
  {'value': 'light', 'label': 'theme.light'.i, 'result': Brightness.light},
];

List<Map> get accentColors => [
  {'value': 'purple', 'label': 'color.purple'.i, 'result': Colors.purple},
  {'value': 'blue', 'label': 'color.blue'.i, 'result': Colors.blue},
  {'value': 'yellow', 'label': 'color.yellow'.i, 'result': Colors.yellow},
  {'value': 'red', 'label': 'color.red'.i, 'result': Colors.red},
  {'value': 'green', 'label': 'color.green'.i, 'result': Colors.green},
  {'value': 'orange', 'label': 'color.orange'.i, 'result': Colors.orange},
  {'value': 'teal', 'label': 'color.teal'.i, 'result': Colors.teal},
];

class AppDb extends BaseDb {
  @override
  String get prefix => 'app';

  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  @override
  Future<void> firstInitDb() async {
    prefs.setString('app.theme', 'light');
    prefs.setBool('app.initialed', true);
  }

  Brightness get theme =>
      getValue('theme') == 'dark' ? Brightness.dark : Brightness.light;
  AccentColor getAccentColor() {
    return accentColors.firstWhere(
      (e) => e['value'] == getValue('accentColor'),
      orElse: () => accentColors.first,
    )['result'];
  }
}
