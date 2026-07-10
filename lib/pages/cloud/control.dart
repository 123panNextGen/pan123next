import 'package:pan123next/common/api/model.dart';
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
      name = formatPhoneNumber(info.passport); // nickName 为用户名, name 为手机号
    } else if (info.mail.isNotEmpty) {
      name = info.mail; // nickName 为用户名, name 为邮箱
    } else {
      name = ''; // nickName 为用户名, name 为空
    }
  } else if (info.passport.isNotEmpty) {
    nickName = formatPhoneNumber(info.passport);
    if (info.mail.isNotEmpty) {
      name = info.mail; // nickName 为手机号, name 为邮箱
    } else {
      name = ''; // nickName 为手机号, name 为空
    }
  } else if (info.mail.isNotEmpty) {
    nickName = info.mail;
    name = ''; // nickName 为邮箱, name 为空
  } else {
    nickName = '空用户名';
    name = '';
  }

  return CloudNameModel(name: name, nickName: nickName);
}
