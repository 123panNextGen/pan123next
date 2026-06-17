import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/base_db.dart';
import 'package:path_provider/path_provider.dart';

class UserDb extends BaseDb {
  static const _prefix = 'user';
  static const _storage = FlutterSecureStorage();

  @override
  String get prefix => _prefix;

  final Map<String, String> _cache = {};
  bool _initialized = false;

  static final UserDb _instance = UserDb._internal();
  factory UserDb() => _instance;
  UserDb._internal();

  Future<String> getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
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

  @override
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

  @override
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

  @override
  void setValue<T>(String key, T value) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    String stringValue;
    if (value is String) {
      stringValue = value;
    } else if (value is bool) {
      stringValue = value.toString();
    } else if (value is int) {
      stringValue = value.toString();
    } else if (value is double) {
      stringValue = value.toString();
    } else if (value is List<String>) {
      stringValue = value.join(',');
    } else {
      stringValue = value.toString();
    }
    _cache[realKey] = stringValue;
    _storage.write(key: realKey, value: stringValue);
  }

  void setUserInfo(UserInfoModel model) {
    setValue('userName', model.userName);
    setValue('password', model.password);
    setValue('uuid', model.uuid);
    setValue('authorization', model.authorization);
    setValue('os', model.device.os);
    setValue('type', model.device.type);
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
