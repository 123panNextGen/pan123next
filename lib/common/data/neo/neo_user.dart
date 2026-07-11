import 'package:pan123next/common/api/model.dart';

class NeoUser {
  final String id;
  String userName;
  String password;
  String authorization;
  String uuid;
  DeviceModel device;
  OpenUserInfoModel? openInfo;
  bool rememberPassword;
  bool isQrCodeLogin;
  DateTime lastLogin;

  NeoUser({
    required this.id,
    required this.userName,
    this.password = '',
    this.authorization = '',
    this.uuid = '',
    DeviceModel? device,
    this.openInfo,
    this.rememberPassword = false,
    this.isQrCodeLogin = false,
    DateTime? lastLogin,
  })  : device = device ?? DeviceModel(os: '', type: ''),
        lastLogin = lastLogin ?? DateTime.now();

  factory NeoUser.fromUserInfoModel(UserInfoModel model) {
    return NeoUser(
      id: model.userName,
      userName: model.userName,
      password: model.password,
      authorization: model.authorization,
      uuid: model.uuid,
      device: DeviceModel(os: model.device.os, type: model.device.type),
      openInfo: model.openInfo,
    );
  }

  UserInfoModel toUserInfoModel() {
    return UserInfoModel(
      userName: userName,
      password: password,
      uuid: uuid,
      authorization: authorization,
      device: DeviceModel(os: device.os, type: device.type),
      openInfo: openInfo,
    );
  }

  NeoUser copyWith({
    String? userName,
    String? password,
    String? authorization,
    String? uuid,
    DeviceModel? device,
    OpenUserInfoModel? openInfo,
    bool? rememberPassword,
    bool? isQrCodeLogin,
    DateTime? lastLogin,
  }) {
    return NeoUser(
      id: id,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      authorization: authorization ?? this.authorization,
      uuid: uuid ?? this.uuid,
      device: device ?? this.device,
      openInfo: openInfo ?? this.openInfo,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      isQrCodeLogin: isQrCodeLogin ?? this.isQrCodeLogin,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'NeoUser(id: $id, userName: $userName, rememberPassword: $rememberPassword, isQrCodeLogin: $isQrCodeLogin, device: $device, hasOpenInfo: ${openInfo != null})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NeoUser && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
