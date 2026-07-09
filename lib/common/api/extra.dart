import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/const.dart';
import 'package:pan123next/common/data/user.dart';

Future<ApiReturnModel<UserInfoModel>> loginWithUserInfo(
  UserInfoModel userInfo,
) async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    final response = await dio.post('/b/api/user/sign_in', data: {
      'type': 1,
      'passport': userInfo.userName,
      'password': userInfo.password,
    });

    if (response.statusCode == 200) {
      final Map content = response.data;
      final returnCode = content['code'];
      if (returnCode != 200) {
        return ApiReturnModel<UserInfoModel>(
          code: response.statusCode ?? 0,
          apiCode: returnCode,
          apiCodeEnum: ApiCode.fail,
          msg: content['message'] ?? '登录失败',
        );
      }

      final newUserInfo = UserInfoModel(
        userName: userInfo.userName,
        password: userInfo.password,
        uuid: userInfo.uuid,
        authorization: 'Bearer ${content['data']['token']}',
        device: userInfo.device,
      );

      return ApiReturnModel<UserInfoModel>(
        code: response.statusCode ?? 0,
        apiCode: returnCode,
        apiCodeEnum: ApiCode.success,
        msg: content['message'] ?? '登录成功',
        data: newUserInfo,
      );
    }

    return ApiReturnModel<UserInfoModel>(
      code: response.statusCode ?? 0,
      apiCode: -1,
      apiCodeEnum: ApiCode.fail,
      msg: '登录失败',
    );
  } catch (e) {
    return ApiReturnModel<UserInfoModel>(
      code: 0,
      apiCode: -1,
      apiCodeEnum: ApiCode.fail,
      msg: e.toString(),
    );
  }
}

Future<void> updateUserInfoSession(UserInfoModel userInfo) async {
  final session = Get.find<NetSession>();
  final db = Get.find<UserDb>();

  session.setUserInformation(userInfo);
  await db.setUserInfo(userInfo);
}
