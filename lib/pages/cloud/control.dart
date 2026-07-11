import 'package:get/get.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/pages/cloud/model.dart';

CloudNameModel getCloudName(OpenUserInfoModel? openInfo) {
  final info = openInfo;

  if (info == null) {
    return CloudNameModel(name: '', nickName: '空用户名');
  }

  late String nickName;
  late String name;

  if (info.nickname.isNotEmpty) {
    nickName = info.nickname;
    if (info.passport.isNotEmpty) {
      name = formatPhoneNumber(info.passport);
    } else if (info.mail.isNotEmpty) {
      name = info.mail;
    } else {
      name = '';
    }
  } else if (info.passport.isNotEmpty) {
    nickName = formatPhoneNumber(info.passport);
    if (info.mail.isNotEmpty) {
      name = info.mail;
    } else {
      name = '';
    }
  } else if (info.mail.isNotEmpty) {
    nickName = info.mail;
    name = '';
  } else {
    nickName = '空用户名';
    name = '';
  }

  return CloudNameModel(name: name, nickName: nickName);
}

Future<ApiReturnModel> switchToUser(NeoUser targetUser) async {
  final session = Get.find<NetSession>();
  final neoDb = Get.find<NeoDb>();
  final appSession = Get.find<AppSession>();

  session.setUserInformation(targetUser.toUserInfoModel());

  try {
    final result = await session.getOpenUserInfo();
    if (result.apiCodeEnum == ApiCode.success) {
      if (session.userInformation != null) {
        session.userInformation!.openInfo = result.data;
      }
      targetUser = targetUser.copyWith(openInfo: result.data);
    }
  } catch (e) {
    return ApiReturnModel(
      code: 0,
      apiCode: 0,
      apiCodeEnum: ApiCode.fail,
      msg: e.toString(),
    );
  }

  await neoDb.saveUser(targetUser, asCurrent: true);
  appSession.userSwitchSignal.value++;

  return ApiReturnModel(
    code: 0,
    apiCode: 0,
    apiCodeEnum: ApiCode.success,
    msg: '已切换到 ${targetUser.userName}',
  );
}
