import 'package:get/get.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';

class ExtraApiService {
  static ExtraApiService get to => Get.find<ExtraApiService>();

  final NetSession _session;

  ExtraApiService({NetSession? session})
    : _session = session ?? Get.find<NetSession>();

  /// 先写入 NetSession，再复用 NetSession.login() 完成登录，
  /// 成功时返回带更新后 authorization 的 UserInfoModel 拷贝
  Future<ApiReturnModel<UserInfoModel>> loginWithUserInfo(
    UserInfoModel userInfo,
  ) async {
    final oldAuth = userInfo.authorization;
    userInfo.authorization = '';
    _session.setUserInformation(userInfo);

    final result = await _session.login();

    if (result.apiCodeEnum == ApiCode.success) {
      final updated = _session.userInformation!;
      return ApiReturnModel<UserInfoModel>(
        code: result.code,
        apiCode: result.apiCode,
        apiCodeEnum: result.apiCodeEnum,
        msg: result.msg,
        data: UserInfoModel(
          userName: updated.userName,
          password: updated.password,
          uuid: updated.uuid,
          authorization: updated.authorization,
          device: updated.device,
          openInfo: updated.openInfo,
        ),
      );
    }

    userInfo.authorization = oldAuth;
    _session.setUserInformation(userInfo);

    return ApiReturnModel<UserInfoModel>(
      code: result.code,
      apiCode: result.apiCode,
      apiCodeEnum: result.apiCodeEnum,
      msg: result.msg,
    );
  }

  /// 同步用户信息到内存会话 (NetSession) 和 / 或本地持久化
  /// - save=true 时写入 NeoDb
  /// - updateSession=true 时更新 NetSession
  Future<void> updateUserInfoSession(
    UserInfoModel userInfo, {
    bool save = true,
    bool updateSession = true,
  }) async {
    if (updateSession) _session.setUserInformation(userInfo);
    if (save) {
      final neoDb = Get.find<NeoDb>();
      final currentId = neoDb.currentUserId;
      if (currentId != null && userInfo.openInfo != null) {
        await neoDb.updateUserOpenInfo(currentId, userInfo.openInfo!);
      }
    }
  }

  /// 清空内存会话，返回登录页面（保留用户凭据）
  Future<void> logout() async {
    _session.clearSession();

    final appSession = Get.find<AppSession>();
    appSession.isLoggedIn.value = false;
  }
}
