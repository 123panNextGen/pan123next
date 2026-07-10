import 'dart:io';

import 'package:get/get.dart';
import 'package:pan123next/common/api/device.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';
import 'package:uuid/uuid.dart';

Future<Map<String, dynamic>> getUserInfo() async {
  final neoDb = Get.find<NeoDb>();
  final current = await neoDb.getCurrentUser();

  if (current == null) {
    return {
      'userName': '',
      'password': '',
      'rememberPassword': false,
    };
  }

  return {
    'userName': current.userName,
    'password': current.password,
    'rememberPassword': current.rememberPassword,
  };
}

Future<ApiReturnModel> login(
  String userName,
  String password,
  bool rememberPassword,
) async {
  final session = Get.find<NetSession>();
  final neoDb = Get.find<NeoDb>();

  final existing = await neoDb.getUser(userName);
  if (existing != null &&
      existing.authorization.isNotEmpty &&
      rememberPassword) {
    final updated = existing.copyWith(
      password: password,
      rememberPassword: rememberPassword,
    );
    session.setUserInformation(updated.toUserInfoModel());
    await neoDb.saveUser(updated, asCurrent: true);

    return ApiReturnModel(
      code: 0,
      apiCode: 0,
      apiCodeEnum: ApiCode.success,
      msg: '登录成功',
    );
  }

  final model = UserInfoModel(
    userName: userName,
    password: password,
    uuid: const Uuid().v4(),
    authorization: '',
    device: DeviceModel(
      os: (await getRandomDevice())['os'],
      type: (await getRandomDevice())['type'],
    ),
  );

  session.setUserInformation(model);

  final returnModel = await session.login();
  if (returnModel.apiCodeEnum == ApiCode.success) {
    final updated = session.userInformation!;
    final neoUser = NeoUser(
      id: userName,
      userName: userName,
      password: rememberPassword ? updated.password : '',
      authorization: updated.authorization,
      uuid: updated.uuid,
      device: updated.device,
      openInfo: updated.openInfo,
      rememberPassword: rememberPassword,
    );
    await neoDb.saveUser(neoUser, asCurrent: true);
  }

  return returnModel;
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

/// 通过登录 API 验证用户密码是否正确（不持久化 session）
Future<bool> verifyPassword(NeoUser user, String password) async {
  final session = Get.find<NetSession>();
  final model = user.toUserInfoModel();
  model.password = password;
  model.authorization = '';
  session.setUserInformation(model);

  final result = await session.login();
  session.clearSession();
  return result.apiCodeEnum == ApiCode.success;
}

void exitProgram() {
  exit(0);
}
