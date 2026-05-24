import 'package:dio/dio.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/i18n/i18n.dart';

class NetSession {
  static final NetSession _instance = NetSession._internal();

  factory NetSession() => _instance;

  NetSession._internal() {
    _initDio();
  }

  late final Dio _dio;
  Map<String, dynamic> headers = {};
  UserInfoModel? _userInformation;
  String cookie = '';

  UserInfoModel? get userInformation => _userInformation;

  void setUserInformation(UserInfoModel userInfo) {
    _userInformation = userInfo;
    _updateHeaders();
  }

  void updateUserInfo(UserInfoModel userInfo) {
    _userInformation = userInfo;
    _updateHeaders();
  }

  Dio get dio {
    if (_userInformation == null) {
      throw Exception('请先调用 setUserInformation 设置用户信息');
    }
    return _dio;
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.123pan.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(headers);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void _updateHeaders() {
    if (_userInformation == null) return;
    headers = buildHeadersForUser(_userInformation!);
  }

  static Map<String, dynamic> buildHeadersForUser(UserInfoModel userInfo) {
    final headers = <String, dynamic>{
      'user-agent': '123pan/v2.4.0(${userInfo.device.os};Xiaomi)',
      'accept-encoding': 'gzip',
      'content-type': 'application/json',
      'osversion': userInfo.device.os,
      'loginuuid': userInfo.uuid,
      'platform': 'android',
      'devicetype': userInfo.device.type,
      'devicename': 'Xiaomi',
      'host': 'www.123pan.com',
      'app-version': '61',
      'x-app-version': '2.4.0',
    };
    if (userInfo.authorization.isNotEmpty) {
      headers['authorization'] = userInfo.authorization;
    }
    return headers;
  }

  Future<ApiReturnModel> login() async {
    int returnCode = 0;
    Map data = {
      'type': 1,
      'passport': _userInformation!.userName,
      'password': _userInformation!.password,
    };

    final response = await dio.post('/b/api/user/sign_in', data: data);

    if (response.statusCode == 200) {
      // 解析 JSON 响应
      final Map content = response.data;
      returnCode = content['code'];
      if (returnCode != 200) {
        return ApiReturnModel(
          code: response.statusCode ?? 0,
          apiCode: returnCode,
          apiCodeEnum: ApiCode.fail,
          msg: content['message'] ?? 'api.login.failed'.i,
        );
      }

      _userInformation!.authorization = 'Bearer ${content['data']['token']}';

      _updateHeaders();
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: returnCode,
        apiCodeEnum: ApiCode.success,
        msg: content['message'] ?? 'login.success'.i,
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: returnCode,
      apiCodeEnum: ApiCode.fail,
      msg: 'api.login.failed'.i,
    );
  }

  // Pan API

  Future<ApiReturnModel> getFileList(
    String fileId, {
    bool reverse = false,
    bool trashed = false,
  }) async {
    int page = 1;
    String next = '';
    List<FileItemModel> allFiles = [];

    while (next != '-1') {
      final response = await dio.get(
        '/api/file/list/new',
        queryParameters: {
          'driveId': '0',
          'parentFileId': fileId,
          'limit': 20,
          'page': page,
          'orderBy': 'file_name',
          'orderDirection': 'desc',
          'trashed': trashed,
        },
      );

      final fileListResponse = FileListResponse.fromJson(response.data);
      allFiles.addAll(fileListResponse.data.infoList);

      if (response.data['code'] == 401) {
        return ApiReturnModel(
          code: response.statusCode ?? 0,
          apiCode: 401,
          apiCodeEnum: ApiCode.fail,
          msg: '登录过期，请重新登录',
        );
      }

      next = fileListResponse.data.next;
      if (next != '-1') {
        page++;
      }
    }

    return ApiReturnModel(
      code: 200,
      apiCode: 200,
      apiCodeEnum: ApiCode.success,
      msg: 'ok',
      data: FileListResponse(
        code: 0,
        message: 'ok',
        data: FileListData(
          next: '-1',
          len: allFiles.length,
          isFirst: true,
          total: allFiles.length,
          infoList: reverse ? allFiles.reversed.toList() : allFiles,
        ),
      ),
    );
  }

  Future<ApiReturnModel> getTrashList(
    String fileId, {
    bool reverse = false,
  }) async {
    return await getFileList(fileId, trashed: true, reverse: reverse);
  }

  Future<ApiReturnModel> createDir(String fileName, String fileId) async {
    final response = await dio.post(
      '/a/api/file/upload_request',
      data: {
        'driveId': '0',
        'etag': '',
        'fileName': fileName,
        'parentFileId': fileId,
        'type': 1,
        'size': 0,
        'duplicate': 1,
        'NotReuse': true,
        'event': 'newCreateFolder',
        'operateType': 1,
      },
    );

    if (response.data['code'] != 0) {
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.fail,
        msg: response.data['message'] ?? 'api.create.failed'.i,
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: response.data['code'],
      apiCodeEnum: ApiCode.success,
      msg: response.data['message'] ?? 'api.create.success'.i,
    );
  }

  Future<ApiReturnModel> trashFile(
    FileItemModel file, [
    bool operation = true,
  ]) async {
    final response = await dio.post(
      '/a/api/file/trash',
      data: {
        'driveId': '0',
        'fileTrashInfoList': file.toJson(),
        'operation': operation,
      },
    );

    if (response.data['code'] != 0) {
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.fail,
        msg: response.data['message'] ?? 'api.delete.failed'.i,
        data: response.data,
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: response.data['code'],
      apiCodeEnum: ApiCode.success,
      msg: response.data['message'] ?? 'api.delete.success'.i,
      data: response.data,
    );
  }

  Future<ApiReturnModel> getFileLink(FileItemModel file) async {
    Response response;

    if (file.isFolder) {
      response = await dio.post(
        '/a/api/file/batch_download_info',
        data: {
          'fileIdList': [
            {'fileId': file.fileId},
          ],
        },
      );
    } else {
      response = await dio.post(
        '/a/api/file/download_info',
        data: {
          'driveId': '0',
          'etag': file.etag,
          'fileId': file.fileId,
          's3keyFlag': file.s3keyFlag,
          'type': file.type,
          'fileName': file.fileName,
          'size': file.size,
        },
      );
    }

    if (response.data['code'] != 0) {
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.fail,
        msg: response.data['message'] ?? 'api.get.link.failed'.i,
      );
    }

    String downloadUrl = response.data['data']['DownloadUrl'] ?? '';

    if (downloadUrl.isNotEmpty) {
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: 0,
        apiCodeEnum: ApiCode.success,
        msg: '',
        data: downloadUrl,
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: 404,
      apiCodeEnum: ApiCode.fail,
      msg: 'api.link.not.found'.i,
    );
  }

  Future<ApiReturnModel> renameFile(String fileId, String newName) {
    return dio.post(
      '/a/api/file/rename',
      data: {
        'driveId': '0',
        'fileId': fileId,
        'fileName': newName,
      },
    ).then((response) {
      if (response.data['code'] != 0) {
        return ApiReturnModel(
          code: response.statusCode ?? 0,
          apiCode: response.data['code'],
          apiCodeEnum: ApiCode.fail,
          msg: response.data['message'] ?? 'api.rename.failed'.i,
        );
      }

      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.success,
        msg: response.data['message'] ?? 'api.rename.success'.i,
      );
    }).catchError((error) {
      return ApiReturnModel(
        code: error.response?.statusCode ?? 0,
        apiCode: error.response?.data['code'] ?? 0,
        apiCodeEnum: ApiCode.fail,
        msg: error.response?.data['message'] ?? 'api.rename.failed'.i,
      );
    });
  }
}
