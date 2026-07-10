import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';

class NeoDb {
  static const _prefix = 'neo';
  static const _userIdsKey = '$_prefix.userIds';
  static const _currentUserIdKey = '$_prefix.currentUserId';

  final FlutterSecureStorage _storage;
  List<String> _userIds = [];
  String? _currentUserId;
  bool _initialized = false;

  NeoDb._(this._storage);

  static Future<NeoDb> create() async {
    final storage = const FlutterSecureStorage();
    final db = NeoDb._(storage);
    await db._init();
    return db;
  }

  Future<void> _init() async {
    final idsRaw = await _storage.read(key: _userIdsKey);
    if (idsRaw != null && idsRaw.isNotEmpty) {
      _userIds = (jsonDecode(idsRaw) as List).cast<String>();
    }
    _currentUserId = await _storage.read(key: _currentUserIdKey);
    _initialized = true;
  }

  bool get isInitialized => _initialized;
  String? get currentUserId => _currentUserId;

  Future<List<NeoUser>> getAllUsers() async {
    final users = <NeoUser>[];
    for (final id in _userIds) {
      final user = await _loadUser(id);
      if (user != null) users.add(user);
    }
    users.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
    return users;
  }

  Future<NeoUser?> getUser(String id) async {
    return _loadUser(id);
  }

  Future<NeoUser?> getCurrentUser() async {
    if (_currentUserId == null) return null;
    return _loadUser(_currentUserId!);
  }

  Future<void> saveUser(NeoUser user, {bool asCurrent = false}) async {
    user.lastLogin = DateTime.now();
    await _saveUser(user);
    if (!_userIds.contains(user.id)) {
      _userIds.add(user.id);
      await _persistUserIds();
    }
    if (asCurrent) {
      await setCurrentUser(user.id);
    }
  }

  Future<void> deleteUser(String id) async {
    _userIds.remove(id);
    await _persistUserIds();
    await _deleteUserKeys(id);
    if (_currentUserId == id) {
      _currentUserId = null;
      await _storage.delete(key: _currentUserIdKey);
    }
  }

  Future<void> setCurrentUser(String id) async {
    _currentUserId = id;
    await _storage.write(key: _currentUserIdKey, value: id);
  }

  Future<void> clearCurrentUser() async {
    _currentUserId = null;
    await _storage.delete(key: _currentUserIdKey);
  }

  Future<bool> hasUsers() async {
    return _userIds.isNotEmpty;
  }

  Future<int> userCount() async {
    return _userIds.length;
  }

  Future<void> updateUserOpenInfo(String id, OpenUserInfoModel openInfo) async {
    await _storage.write(
      key: _key(id, 'openInfo'),
      value: jsonEncode(openInfo.toJson()),
    );
  }

  Future<void> updateLastLogin(String id) async {
    await _storage.write(
      key: _key(id, 'lastLogin'),
      value: DateTime.now().toIso8601String(),
    );
  }

  String _key(String id, String field) => '$_prefix.user.$id.$field';

  Future<void> _persistUserIds() async {
    await _storage.write(
      key: _userIdsKey,
      value: jsonEncode(_userIds),
    );
  }

  Future<void> _saveUser(NeoUser user) async {
    final w = _storage.write;
    await w(key: _key(user.id, 'userName'), value: user.userName);
    await w(key: _key(user.id, 'password'), value: user.password);
    await w(key: _key(user.id, 'authorization'), value: user.authorization);
    await w(key: _key(user.id, 'uuid'), value: user.uuid);
    await w(key: _key(user.id, 'os'), value: user.device.os);
    await w(key: _key(user.id, 'type'), value: user.device.type);
    await w(
      key: _key(user.id, 'rememberPassword'),
      value: user.rememberPassword.toString(),
    );
    await w(
      key: _key(user.id, 'autoLogin'),
      value: user.autoLogin.toString(),
    );
    await w(
      key: _key(user.id, 'lastLogin'),
      value: user.lastLogin.toIso8601String(),
    );
    if (user.openInfo != null) {
      await w(
        key: _key(user.id, 'openInfo'),
        value: jsonEncode(user.openInfo!.toJson()),
      );
    }
  }

  Future<NeoUser?> _loadUser(String id) async {
    final r = _storage.read;
    final userName = await r(key: _key(id, 'userName'));
    if (userName == null) return null;

    final password = await r(key: _key(id, 'password')) ?? '';
    final authorization = await r(key: _key(id, 'authorization')) ?? '';
    final uuid = await r(key: _key(id, 'uuid')) ?? '';
    final os = await r(key: _key(id, 'os')) ?? '';
    final type = await r(key: _key(id, 'type')) ?? '';
    final rememberPasswordStr = await r(key: _key(id, 'rememberPassword'));
    final autoLoginStr = await r(key: _key(id, 'autoLogin'));
    final lastLoginStr = await r(key: _key(id, 'lastLogin'));
    final openInfoRaw = await r(key: _key(id, 'openInfo'));

    OpenUserInfoModel? openInfo;
    if (openInfoRaw != null && openInfoRaw.isNotEmpty) {
      final map = jsonDecode(openInfoRaw) as Map<String, dynamic>;
      openInfo = OpenUserInfoModel.fromJson(map);
    }

    return NeoUser(
      id: id,
      userName: userName,
      password: password,
      authorization: authorization,
      uuid: uuid,
      device: DeviceModel(os: os, type: type),
      openInfo: openInfo,
      rememberPassword: rememberPasswordStr == 'true',
      autoLogin: autoLoginStr == 'true',
      lastLogin:
          lastLoginStr != null ? DateTime.parse(lastLoginStr) : DateTime.now(),
    );
  }

  Future<void> _deleteUserKeys(String id) async {
    final d = _storage.delete;
    await d(key: _key(id, 'userName'));
    await d(key: _key(id, 'password'));
    await d(key: _key(id, 'authorization'));
    await d(key: _key(id, 'uuid'));
    await d(key: _key(id, 'os'));
    await d(key: _key(id, 'type'));
    await d(key: _key(id, 'rememberPassword'));
    await d(key: _key(id, 'autoLogin'));
    await d(key: _key(id, 'lastLogin'));
    await d(key: _key(id, 'openInfo'));
  }
}
