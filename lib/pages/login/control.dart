import 'dart:io';

import 'package:get/get.dart';
import 'package:pan123next/common/api/device.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:uuid/uuid.dart';

Map<String, dynamic> getUserInfo() {
  UserDb db = Get.find();
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
  final NetSession session = Get.find();
  final UserDb db = Get.find();
  final NeoDb neoDb = Get.find();
  UserInfoModel model = db.getUserInfo();

  if (model.userName == userName &&
      rememberPassword &&
      model.authorization.isNotEmpty) {
    model.userName = userName;
    model.password = password;
    session.setUserInformation(model);

    await db.setUserInfo(model);
    await db.setValueAsync('autoLogin', autoLogin);
    await db.setValueAsync('rememberPassword', rememberPassword);
    await db.setValueAsync('userName', userName);

    await _saveToNeoDb(neoDb, session, autoLogin, rememberPassword);

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
      await db.setUserInfo(session.userInformation!);
    } else {
      await db.setValueAsync('password', '');
      await db.setValueAsync('authorization', '');
    }
    await db.setValueAsync('autoLogin', autoLogin);
    await db.setValueAsync('rememberPassword', rememberPassword);
    await db.setValueAsync('userName', userName);

    await _saveToNeoDb(neoDb, session, autoLogin, rememberPassword);
  }

  return returnModel;
}

Future<void> _saveToNeoDb(
  NeoDb neoDb,
  NetSession session,
  bool autoLogin,
  bool rememberPassword,
) async {
  final info = session.userInformation;
  if (info == null) return;

  final user = NeoUser(
    id: info.userName,
    userName: info.userName,
    password: rememberPassword ? info.password : '',
    authorization: info.authorization,
    uuid: info.uuid,
    device: info.device,
    openInfo: info.openInfo,
    rememberPassword: rememberPassword,
    autoLogin: autoLogin,
  );
  await neoDb.saveUser(user, asCurrent: true);
}

Future<ApiReturnModel> loginWithNeoUser(NeoUser user) async {
  final session = Get.find<NetSession>();
  final neoDb = Get.find<NeoDb>();

  if (user.authorization.isEmpty) {
    return ApiReturnModel(
      code: 0,
      apiCode: -1,
      apiCodeEnum: ApiCode.fail,
      msg: '登录凭据已失效，请使用密码重新登录',
    );
  }

  session.setUserInformation(user.toUserInfoModel());
  await neoDb.saveUser(user, asCurrent: true);

  return ApiReturnModel(
    code: 0,
    apiCode: 0,
    apiCodeEnum: ApiCode.success,
    msg: '登录成功',
  );
}

void exitProgram() {
  exit(0);
}
