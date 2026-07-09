import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/const.dart';

class NetSession {
  static final NetSession _instance = NetSession._internal();

  factory NetSession() => _instance;

  NetSession._internal() {
    _initDio();
  }

  late final Dio _dio;
  final Map<String, dynamic> headers = {};
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
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(headers);
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final code = response.data?['code'] ?? response.data?['Code'];
          if (code == 401) {
            response.data['message'] = '登录会话已过期，请刷新';
          }
          return handler.next(response);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  void _updateHeaders() {
    if (_userInformation == null) return;
    headers
      ..clear()
      ..addAll(buildHeadersForUser(_userInformation!));
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
      'host': apiBaseUrl.replaceAll('https://', ''),
      'app-version': '61',
      'x-app-version': '2.4.0',
    };
    if (userInfo.authorization.isNotEmpty) {
      headers['authorization'] = userInfo.authorization;
    }
    return headers;
  }

  Future<ApiReturnModel<void>> login() async {
    if (_userInformation == null) {
      return ApiReturnModel<void>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: '请先设置用户信息',
      );
    }
    try {
      int returnCode = 0;
      Map data = {
        'type': 1,
        'passport': _userInformation!.userName,
        'password': _userInformation!.password,
      };

      final response = await dio.post('/b/api/user/sign_in', data: data);

      if (response.statusCode == 200) {
        final Map content = response.data;
        returnCode = content['code'];
        if (returnCode != 200) {
          return ApiReturnModel<void>(
            code: response.statusCode ?? 0,
            apiCode: returnCode,
            apiCodeEnum: ApiCode.fail,
            msg: content['message'] ?? '登录失败',
          );
        }

        _userInformation!.authorization = 'Bearer ${content['data']['token']}';

        _updateHeaders();
        return ApiReturnModel<void>(
          code: response.statusCode ?? 0,
          apiCode: returnCode,
          apiCodeEnum: ApiCode.success,
          msg: content['message'] ?? '登录成功',
        );
      }

      return ApiReturnModel<void>(
        code: response.statusCode ?? 0,
        apiCode: returnCode,
        apiCodeEnum: ApiCode.fail,
        msg: '登录失败',
      );
    } catch (e) {
      return ApiReturnModel<void>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  Future<ApiReturnModel<FileListResponse>> getFileList(
    String fileId, {
    bool reverse = false,
    bool trashed = false,
  }) async {
    try {
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
        final infoList = fileListResponse.data.infoList;
        allFiles.addAll(infoList);

        if (response.data['Code'] == 401 || response.data['code'] == 401) {
          return ApiReturnModel<FileListResponse>(
            code: response.statusCode ?? 0,
            apiCode: 401,
            apiCodeEnum: ApiCode.fail,
            msg: '登录会话已过期，请刷新',
          );
        }

        next = fileListResponse.data.next;
        if (next.isEmpty || infoList.isEmpty) break;
        if (next != '-1') {
          page++;
        }
      }

      return ApiReturnModel<FileListResponse>(
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
    } catch (e) {
      return ApiReturnModel<FileListResponse>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  Future<ApiReturnModel<FileListResponse>> getTrashList(
    String fileId, {
    bool reverse = false,
  }) async {
    return await getFileList(fileId, trashed: true, reverse: reverse);
  }

  Future<ApiReturnModel<void>> createDir(String fileName, String fileId) async {
    try {
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
        return ApiReturnModel<void>(
          code: response.statusCode ?? 0,
          apiCode: response.data['code'],
          apiCodeEnum: ApiCode.fail,
          msg: response.data['message'] ?? '创建失败',
        );
      }

      return ApiReturnModel<void>(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.success,
        msg: response.data['message'] ?? '创建成功',
      );
    } catch (e) {
      return ApiReturnModel<void>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  Future<ApiReturnModel<Map>> trashFile(
    FileItemModel file, [
    bool operation = true,
  ]) async {
    try {
      final response = await dio.post(
        '/a/api/file/trash',
        data: {
          'driveId': '0',
          'fileTrashInfoList': file.toJson(),
          'operation': operation,
        },
      );

      if (response.data['code'] != 0) {
        return ApiReturnModel<Map>(
          code: response.statusCode ?? 0,
          apiCode: response.data['code'],
          apiCodeEnum: ApiCode.fail,
          msg: response.data['message'] ?? '删除失败',
          data: response.data,
        );
      }

      return ApiReturnModel<Map>(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.success,
        msg: response.data['message'] ?? '删除成功',
        data: response.data,
      );
    } catch (e) {
      return ApiReturnModel<Map>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  Future<ApiReturnModel<Map>> restoreFile(FileItemModel file) async {
    return await trashFile(file, false);
  }

  Future<ApiReturnModel<String>> getFileLink(FileItemModel file) async {
    try {
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

      final apiCode = response.data['code'] ?? response.data['Code'];
      final outerData = response.data['data'] ?? response.data['Data'];

      String? downloadUrl;

      // 123pan API 返回结构为 {code, data: {data: {DownloadUrl, ...}}}
      // 尝试两层 data 嵌套
      if (outerData is Map) {
        // 直接取 DownloadUrl（部分接口可能是一层结构）
        downloadUrl = outerData['downloadUrl'] ?? outerData['DownloadUrl'];
        if ((downloadUrl ?? '').isEmpty) {
          // 嵌套 data 层
          final innerData = outerData['data'] ?? outerData['Data'];
          if (innerData is Map) {
            downloadUrl = innerData['downloadUrl'] ?? innerData['DownloadUrl'];
          }
        }
      } else if (outerData is String) {
        downloadUrl = outerData;
      }

      downloadUrl = downloadUrl?.trim();
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        // downloadUrl 是中间跳转地址，跟随 302 获取真实下载链接
        final realUrl = await _resolveDownloadUrl(downloadUrl);
        return ApiReturnModel<String>(
          code: response.statusCode ?? 0,
          apiCode: 0,
          apiCodeEnum: ApiCode.success,
          msg: '',
          data: realUrl,
        );
      }

      if (apiCode != null && apiCode != 0 && apiCode != 200) {
        return ApiReturnModel<String>(
          code: response.statusCode ?? 0,
          apiCode: apiCode,
          apiCodeEnum: ApiCode.fail,
          msg: response.data['message'] ?? '获取文件链接失败',
        );
      }

      return ApiReturnModel<String>(
        code: response.statusCode ?? 0,
        apiCode: 404,
        apiCodeEnum: ApiCode.fail,
        msg: '文件链接不存在',
      );
    } catch (e) {
      return ApiReturnModel<String>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  /// 跟随 302 跳转获取真实下载链接
  Future<String> _resolveDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()
        ..autoUncompress = true
        ..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri);
      // 不自动跟随重定向，手动处理
      final response = await request.close();

      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        final location = response.headers.value('location');
        client.close(force: true);
        if (location != null && location.isNotEmpty) {
          final resolved = Uri.parse(location).isAbsolute
              ? location
              : uri.resolve(location).toString();
          return resolved;
        }
      }

      client.close(force: true);
      return url;
    } catch (e) {
      return url;
    }
  }

  Future<ApiReturnModel<void>> renameFile(String fileId, String newName) async {
    try {
      final response = await dio.post(
        '/a/api/file/rename',
        data: {'driveId': '0', 'fileId': fileId, 'fileName': newName},
      );

      if (response.data['code'] != 0) {
        return ApiReturnModel<void>(
          code: response.statusCode ?? 0,
          apiCode: response.data['code'],
          apiCodeEnum: ApiCode.fail,
          msg: response.data['message'] ?? '重命名失败',
        );
      }

      return ApiReturnModel<void>(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.success,
        msg: response.data['message'] ?? '重命名成功',
      );
    } catch (e) {
      return ApiReturnModel<void>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }

  Future<ApiReturnModel<OpenUserInfoModel>> getOpenUserInfo() async {
    try {
      final openDio = Dio(
        BaseOptions(
          baseUrl: openApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
          responseType: ResponseType.json,
        ),
      );

      final response = await openDio.get(
        '/api/v1/user/info',
        options: Options(
          headers: {
            'Authorization': _userInformation?.authorization ?? '',
            'Platform': 'open_platform',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Map content = response.data;
        final code = content['code'] ?? -1;
        if (code == 0) {
          final rawData = content['data'] ?? <String, dynamic>{};
          return ApiReturnModel<OpenUserInfoModel>(
            code: response.statusCode ?? 0,
            apiCode: code,
            apiCodeEnum: ApiCode.success,
            msg: 'ok',
            data: OpenUserInfoModel.fromJson(rawData as Map<String, dynamic>),
          );
        }
        return ApiReturnModel<OpenUserInfoModel>(
          code: response.statusCode ?? 0,
          apiCode: code,
          apiCodeEnum: ApiCode.fail,
          msg: content['message'] ?? '获取用户信息失败',
        );
      }

      return ApiReturnModel<OpenUserInfoModel>(
        code: response.statusCode ?? 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: '获取用户信息失败',
      );
    } catch (e) {
      return ApiReturnModel<OpenUserInfoModel>(
        code: 0,
        apiCode: -1,
        apiCodeEnum: ApiCode.fail,
        msg: e.toString(),
      );
    }
  }
}
