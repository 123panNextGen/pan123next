import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/base_db.dart';
import 'package:path_provider/path_provider.dart';

class UserDb extends BaseDb {
  static const _prefix = 'user';
  static const _storage = FlutterSecureStorage();

  static final UserDb _instance = UserDb._internal();
  factory UserDb() => _instance;
  UserDb._internal();

  @override
  String get prefix => _prefix;

  @override
  List<String> get keys => [
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

  Future<String> getDownloadPath() async {
    final directory = await getDownloadsDirectory();
    if (directory != null) return directory.path;
    final fallback = await getApplicationDocumentsDirectory();
    return fallback.path;
  }

  @override
  Future<void> initDb() async {
    if (initialized) return;

    for (final key in keys) {
      final value = await _storage.read(key: key);
      if (value != null) {
        cache[key] = value;
      }
    }

    if (!(cache['$_prefix.initialed'] == 'true')) {
      initialized = true;
      await firstInitDb();
      cache['$_prefix.initialed'] = 'true';
      await _storage.write(key: '$_prefix.initialed', value: 'true');
    } else {
      initialized = true;
    }
  }

  @override
  Future<void> firstInitDb() async {
    final downloadPath = await getDownloadPath();

    await _setValue('userName', '');
    await _setValue('password', '');
    await _setValue('uuid', '');
    await _setValue('authorization', '');
    await _setValue('os', '');
    await _setValue('type', '');
    await _setValue('autoLogin', 'false');
    await _setValue('rememberPassword', 'false');
    await _setValue('set.askDownload', 'true');
    await _setValue('set.defaultDownloadPath', downloadPath);
  }

  @override
  dynamic getValue(String key) {
    if (!initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    final value = cache[realKey] as String?;
    if (value == null) return null;

    if (value == 'true') return true;
    if (value == 'false') return false;
    return value;
  }

  @override
  void setValue<T>(String key, T value) {
    if (!initialized) {
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
    cache[realKey] = stringValue;
    _storage.write(key: realKey, value: stringValue);
  }

  Future<void> setUserInfo(UserInfoModel model) async {
    await _setValue('userName', model.userName);
    await _setValue('password', model.password);
    await _setValue('uuid', model.uuid);
    await _setValue('authorization', model.authorization);
    await _setValue('os', model.device.os);
    await _setValue('type', model.device.type);
  }

  Future<void> _setValue(String key, String value) async {
    final realKey = '$_prefix.$key';
    cache[realKey] = value;
    await _storage.write(key: realKey, value: value);
  }

  Future<void> setValueAsync<T>(String key, T value) async {
    if (!initialized) {
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
    cache[realKey] = stringValue;
    await _storage.write(key: realKey, value: stringValue);
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
