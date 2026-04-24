import 'package:dio/dio.dart';
import 'package:pan123next/common/api/model.dart';

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
        responseHeader: true,
        responseBody: true,
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

    headers = {
      'user-agent': '123pan/v2.4.0(${_userInformation!.device.os};Xiaomi)',
      'authorization': _userInformation!.authorization,
      'accept-encoding': 'gzip',
      'content-type': 'application/json',
      'osversion': _userInformation!.device.os,
      'loginuuid': _userInformation!.uuid,
      'platform': 'android',
      'devicetype': _userInformation!.device.type,
      'devicename': 'Xiaomi',
      'host': 'www.123pan.com',
      'app-version': '61',
      'x-app-version': '2.4.0',
    };
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
          msg: content['message'] ?? '登录失败',
        );
      }

      // 更新用户信息
      _userInformation!.authorization = 'Bearer ${content['data']['token']}';

      _updateHeaders();
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: returnCode,
        apiCodeEnum: ApiCode.success,
        msg: content['message'] ?? '登录成功',
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: returnCode,
      apiCodeEnum: ApiCode.fail,
      msg: '登录失败',
    );
  }

  // Pan API

  Future<ApiReturnModel> getFileList(String fileId) async {
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
          'trashed': false,
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
          infoList: allFiles,
        ),
      ),
    );
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

    if  (response.data['code'] != 0) {
      return ApiReturnModel(
        code: response.statusCode ?? 0,
        apiCode: response.data['code'],
        apiCodeEnum: ApiCode.fail,
        msg: response.data['message'] ?? '创建失败',
      );
    }

    return ApiReturnModel(
      code: response.statusCode ?? 0,
      apiCode: response.data['code'],
      apiCodeEnum: ApiCode.success,
      msg: response.data['message'] ?? '创建成功',
    );
  }
}
