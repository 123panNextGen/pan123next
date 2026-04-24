import 'package:pan123next/common/api/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDb {
  static final UserDb _instance = UserDb._internal();
  factory UserDb() => _instance;
  UserDb._internal();

  SharedPreferences? _prefs;

  Future<void> initDb() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    try {
      if (!(_prefs!.getBool('user.initialed') ?? false)) _firstInitDb();
    } catch (e) {
      _firstInitDb();
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _prefs!;
  }

  void _firstInitDb() {
    prefs.setString('user.userName', '');
    prefs.setString('user.password', '');
    prefs.setString('user.uuid', '');
    prefs.setString('user.authorization', '');
    prefs.setString('user.os', '');
    prefs.setString('user.type', '');

    prefs.setBool('user.autoLogin', false);
    prefs.setBool('user.rememberPassword', false);

    prefs.setBool('user.initialed', true);
  }

  void setUserInfo(UserInfoModel model) {
    prefs.setString('user.userName', model.userName);
    prefs.setString('user.password', model.password);
    prefs.setString('user.uuid', model.uuid);
    prefs.setString('user.authorization', model.authorization);
    prefs.setString('user.os', model.device.os);
    prefs.setString('user.type', model.device.type);
  }

  UserInfoModel getUserInfo() {
    return UserInfoModel(
      userName: prefs.getString('user.userName') ?? '',
      password: prefs.getString('user.password') ?? '',
      uuid: prefs.getString('user.uuid') ?? '',
      authorization: prefs.getString('user.authorization') ?? '',
      device: DeviceModel(
        os: prefs.getString('user.os') ?? '',
        type: prefs.getString('user.type') ?? '',
      ),
    );
  }

  dynamic getValue(String key) {
    if (key.isEmpty) return;
    return prefs.get('user.$key');
  }

  void setValue(String key, dynamic value, String type) {
    if (key.isEmpty) return;
    String realKey = 'user.$key';

    switch (type) {
      case 'string':
        prefs.setString(realKey, value);
        break;
      case 'bool':
        prefs.setBool(realKey, value);
        break;
      case 'int':
        prefs.setInt(realKey, value);
        break;
      default:
        break;
    }
  }
}
