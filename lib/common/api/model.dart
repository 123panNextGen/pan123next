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
