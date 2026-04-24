import 'package:pan123next/common/api/device.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:uuid/uuid.dart';

Map<String, dynamic> getUserInfo() {
  UserDb db = UserDb();
  UserInfoModel model = db.getUserInfo();

  return {
    'userName': model.userName,
    'password': model.password,
    'autoLogin': db.getValue('autoLogin') ?? false,
    'rememberPassword': db.getValue('rememberPassword') ?? false,
  };
}

Future<ApiReturnModel> login(
  String userName,
  String password,
  bool autoLogin,
  bool rememberPassword,
) async {
  final NetSession session = NetSession();
  UserDb db = UserDb();
  UserInfoModel model = db.getUserInfo();

  if (model.userName == userName &&
      rememberPassword &&
      model.authorization.isNotEmpty) {
    model.userName = userName;
    model.password = password;
    session.setUserInformation(model);

    return ApiReturnModel(
      code: 0,
      apiCode: 0,
      apiCodeEnum: ApiCode.success,
      msg: '登录成功',
    );
  }

  model.userName = userName;
  model.password = password;

  if (model.uuid.isEmpty) model.uuid = const Uuid().v4();
  if (model.device.type.isEmpty) {
    model.device.type = (await getRandomDevice())['type'];
  }
  if (model.device.os.isEmpty) {
    model.device.os = (await getRandomDevice())['os'];
  }

  session.setUserInformation(model);

  ApiReturnModel returnModel = await session.login();
  if (returnModel.apiCodeEnum == ApiCode.success) {
    if (rememberPassword) {
      db.setUserInfo(session.userInformation!);
    } else {
      db.setValue('password', '', 'string');
      db.setValue('authorization', '', 'string');
    }
    db.setValue('autoLogin', autoLogin, 'bool');
    db.setValue('rememberPassword', rememberPassword, 'bool');

    db.setValue('userName', userName, 'string');
  }

  return returnModel;
}
