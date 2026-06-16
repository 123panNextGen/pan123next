import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:path_provider/path_provider.dart';

class UserDb {
  static const _prefix = 'user';
  static const _storage = FlutterSecureStorage();

  final Map<String, String> _cache = {};
  bool _initialized = false;

  static final UserDb _instance = UserDb._internal();
  factory UserDb() => _instance;
  UserDb._internal();

  Future<String> getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> initDb() async {
    if (_initialized) return;

    const keys = [
      '$_prefix.userName',
      '$_prefix.password',
      '$_prefix.uuid',
      '$_prefix.authorization',
      '$_prefix.os',
      '$_prefix.type',
      '$_prefix.autoLogin',
      '$_prefix.rememberPassword',
      '$_prefix.set.askDownload',
      '$_prefix.set.defaultDownloadPath',
      '$_prefix.set.language',
      '$_prefix.initialed',
    ];

    for (final key in keys) {
      final value = await _storage.read(key: key);
      if (value != null) {
        _cache[key] = value;
      }
    }

    if (!(_cache['$_prefix.initialed'] == 'true')) {
      await firstInitDb();
    }

    _initialized = true;
  }

  Future<void> firstInitDb() async {
    final downloadPath = await getDownloadPath();

    await _set('$_prefix.userName', '');
    await _set('$_prefix.password', '');
    await _set('$_prefix.uuid', '');
    await _set('$_prefix.authorization', '');
    await _set('$_prefix.os', '');
    await _set('$_prefix.type', '');

    await _set('$_prefix.autoLogin', 'false');
    await _set('$_prefix.rememberPassword', 'false');

    await _set('$_prefix.set.askDownload', 'true');
    await _set('$_prefix.set.defaultDownloadPath', downloadPath);

    await _set('$_prefix.initialed', 'true');
  }

  Future<void> _set(String key, String value) async {
    _cache[key] = value;
    await _storage.write(key: key, value: value);
  }

  dynamic getValue(String key) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    final value = _cache[realKey];
    if (value == null) return null;

    // auto-convert bool-like values for convenience
    if (value == 'true') return true;
    if (value == 'false') return false;
    return value;
  }

  void setValue(String key, dynamic value, String type) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    String stringValue;
    switch (type) {
      case 'bool':
        stringValue = value.toString();
        break;
      case 'int':
        stringValue = value.toString();
        break;
      case 'string':
      default:
        stringValue = value.toString();
        break;
    }
    _cache[realKey] = stringValue;
    _storage.write(key: realKey, value: stringValue);
  }

  void setUserInfo(UserInfoModel model) {
    setValue('userName', model.userName, 'string');
    setValue('password', model.password, 'string');
    setValue('uuid', model.uuid, 'string');
    setValue('authorization', model.authorization, 'string');
    setValue('os', model.device.os, 'string');
    setValue('type', model.device.type, 'string');
  }

  UserInfoModel getUserInfo() {
    return UserInfoModel(
      userName: getValue('userName') ?? '',
      password: getValue('password') ?? '',
      uuid: getValue('uuid') ?? '',
      authorization: getValue('authorization') ?? '',
      device: DeviceModel(
        os: getValue('os') ?? '',
        type: getValue('type') ?? '',
      ),
    );
  }
}
