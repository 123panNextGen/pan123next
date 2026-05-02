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

  UserInfoModel({
    required this.userName,
    required this.password,
    required this.uuid,
    required this.authorization,
    required this.device,
  });
}

enum ApiCode { success, fail }

class ApiReturnModel {
  int code;
  int apiCode;
  ApiCode apiCodeEnum;
  String msg;
  dynamic data;

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
      fileId: json['FileId'] ?? 0,
      fileName: json['FileName'] ?? '',
      type: json['Type'] ?? 0,
      size: json['Size'] ?? 0,
      etag: json['Etag'] ?? '',
      s3keyFlag: json['S3keyFlag'] ?? '',
      contentType: json['ContentType'] ?? '',
      createAt: json['CreateAt'] ?? '',
      updateAt: json['UpdateAt'] ?? '',
      hidden: json['Hidden'] ?? false,
      parentFileId: json['ParentFileId'] ?? 0,
      pinYin: json['PinYin'] ?? '',
      starredStatus: json['StarredStatus'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'FileId': fileId,
    'FileName': fileName,
    'Type': type,
    'Size': size,
    'Etag': etag,
    'S3keyFlag': s3keyFlag,
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
    return FileListResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: FileListData.fromJson(json['data'] ?? {}),
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
    return FileListData(
      next: json['Next'] ?? '',
      len: json['Len'] ?? 0,
      isFirst: json['IsFirst'] ?? false,
      total: json['Total'] ?? 0,
      infoList:
          (json['InfoList'] as List?)
              ?.map((item) => FileItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
