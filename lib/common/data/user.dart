import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/base_db.dart';
import 'package:path_provider/path_provider.dart';

class UserDb extends BaseDb {
  @override
  String get prefix => 'user';

  static final UserDb _instance = UserDb._internal();
  factory UserDb() => _instance;
  UserDb._internal();

  Future<String> getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<void> firstInitDb() async {
    prefs.setString('user.userName', '');
    prefs.setString('user.password', '');
    prefs.setString('user.uuid', '');
    prefs.setString('user.authorization', '');
    prefs.setString('user.os', '');
    prefs.setString('user.type', '');

    prefs.setBool('user.autoLogin', false);
    prefs.setBool('user.rememberPassword', false);

    prefs.setBool('user.set.askDownload', true);
    prefs.setString('user.set.defaultDownloadPath', await getDownloadPath());

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
}
