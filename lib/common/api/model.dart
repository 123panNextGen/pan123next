class DeviceModel {
  String os;
  String type;

  DeviceModel({required this.os, required this.type});
}

class UserInfoModel {
  String userName;
  String password;

  String uuid;
  String authorization;
  DeviceModel device;
  OpenUserInfoModel? openInfo;

  UserInfoModel({
    required this.userName,
    required this.password,
    required this.uuid,
    required this.authorization,
    required this.device,
    this.openInfo,
  });
}

enum ApiCode { success, fail }

class ApiReturnModel<T> {
  int code;
  int apiCode;
  ApiCode apiCodeEnum;
  String msg;
  T? data;

  ApiReturnModel({
    required this.code,
    required this.apiCode,
    required this.apiCodeEnum,
    required this.msg,
    this.data,
  });
}

class FileItemModel {
  final int fileId;
  final String fileName;
  final int type;
  final int size;
  final String etag;
  final String s3keyFlag;
  final String contentType;
  final String createAt;
  final String updateAt;
  final bool hidden;
  final int parentFileId;
  final String pinYin;
  final bool starredStatus;

  FileItemModel({
    required this.fileId,
    required this.fileName,
    required this.type,
    required this.size,
    required this.etag,
    required this.s3keyFlag,
    required this.contentType,
    required this.createAt,
    required this.updateAt,
    required this.hidden,
    required this.parentFileId,
    required this.pinYin,
    required this.starredStatus,
  });

  factory FileItemModel.fromJson(Map<String, dynamic> json) {
    return FileItemModel(
      fileId: (json['fileId'] ?? json['FileId'] ?? 0) as int,
      fileName: (json['fileName'] ?? json['FileName'] ?? '') as String,
      type: (json['type'] ?? json['Type'] ?? 0) as int,
      size: (json['size'] ?? json['Size'] ?? 0) as int,
      etag: (json['etag'] ?? json['Etag'] ?? '') as String,
      s3keyFlag: (json['s3keyFlag'] ?? json['S3KeyFlag'] ?? '') as String,
      contentType: (json['contentType'] ?? json['ContentType'] ?? '') as String,
      createAt: (json['createAt'] ?? json['CreateAt'] ?? '') as String,
      updateAt: (json['updateAt'] ?? json['UpdateAt'] ?? '') as String,
      hidden: (json['hidden'] ?? json['Hidden'] ?? false) as bool,
      parentFileId: (json['parentFileId'] ?? json['ParentFileId'] ?? 0) as int,
      pinYin: (json['pinYin'] ?? json['PinYin'] ?? '') as String,
      starredStatus: (json['starredStatus'] ?? json['StarredStatus'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'FileId': fileId,
    'FileName': fileName,
    'Type': type,
    'Size': size,
    'Etag': etag,
    'S3KeyFlag': s3keyFlag,
    'ContentType': contentType,
    'CreateAt': createAt,
    'UpdateAt': updateAt,
    'Hidden': hidden,
    'ParentFileId': parentFileId,
    'PinYin': pinYin,
    'StarredStatus': starredStatus ? 1 : 0,
  };

  bool get isFolder => type == 1;
}

class FileListResponse {
  final int code;
  final String message;
  final FileListData data;

  FileListResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['Data'] ?? <String, dynamic>{};
    return FileListResponse(
      code: json['code'] ?? json['Code'] ?? 0,
      message: json['message'] ?? json['Message'] ?? '',
      data: FileListData.fromJson(data as Map<String, dynamic>),
    );
  }
}

class FileListData {
  final String next;
  final int len;
  final bool isFirst;
  final int total;
  final List<FileItemModel> infoList;

  FileListData({
    required this.next,
    required this.len,
    required this.isFirst,
    required this.total,
    required this.infoList,
  });

  factory FileListData.fromJson(Map<String, dynamic> json) {
    final infoListRaw = json['infoList'] ?? json['InfoList'];
    return FileListData(
      next: (json['next'] ?? json['Next'] ?? '') as String,
      len: (json['len'] ?? json['Len'] ?? 0) as int,
      isFirst: (json['isFirst'] ?? json['IsFirst'] ?? false) as bool,
      total: (json['total'] ?? json['Total'] ?? 0) as int,
      infoList:
          (infoListRaw as List?)
              ?.map((item) => FileItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class VipInfo {
  final int vipLevel;
  final String vipLabel;
  final String startTime;
  final String endTime;

  VipInfo({
    required this.vipLevel,
    required this.vipLabel,
    required this.startTime,
    required this.endTime,
  });

  factory VipInfo.fromJson(Map<String, dynamic> json) => VipInfo(
    vipLevel: json['vipLevel'] ?? 0,
    vipLabel: json['vipLabel'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
  );
}

class DeveloperInfo {
  final String startTime;
  final String endTime;

  DeveloperInfo({
    required this.startTime,
    required this.endTime,
  });

  factory DeveloperInfo.fromJson(Map<String, dynamic> json) => DeveloperInfo(
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
  );
}

class OpenUserInfoModel {
  final int uid;
  final String nickname;
  final String headImage;
  final String passport;
  final String mail;
  final int spaceUsed;
  final int spacePermanent;
  final int spaceTemp;
  final String spaceTempExpr;
  final bool vip;
  final int directTraffic;
  final bool isHideUID;
  final int httpsCount;
  final List<VipInfo>? vipInfo;
  final DeveloperInfo? developerInfo;

  OpenUserInfoModel({
    required this.uid,
    required this.nickname,
    required this.headImage,
    required this.passport,
    required this.mail,
    required this.spaceUsed,
    required this.spacePermanent,
    required this.spaceTemp,
    required this.spaceTempExpr,
    required this.vip,
    required this.directTraffic,
    required this.isHideUID,
    required this.httpsCount,
    this.vipInfo,
    this.developerInfo,
  });

  factory OpenUserInfoModel.fromJson(Map<String, dynamic> json) =>
    OpenUserInfoModel(
      uid: json['uid'] ?? 0,
      nickname: json['nickname'] ?? '',
      headImage: json['headImage'] ?? '',
      passport: json['passport'] ?? '',
      mail: json['mail'] ?? '',
      spaceUsed: json['spaceUsed'] ?? 0,
      spacePermanent: json['spacePermanent'] ?? 0,
      spaceTemp: json['spaceTemp'] ?? 0,
      spaceTempExpr: (json['spaceTempExpr'] ?? '').toString(),
      vip: json['vip'] ?? false,
      directTraffic: json['directTraffic'] ?? 0,
      isHideUID: json['isHideUID'] ?? false,
      httpsCount: json['httpsCount'] ?? 0,
      vipInfo: (json['vipInfo'] as List?)
          ?.map((e) => VipInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      developerInfo: json['developerInfo'] != null
          ? DeveloperInfo.fromJson(
              json['developerInfo'] as Map<String, dynamic>)
          : null,
    );
}
