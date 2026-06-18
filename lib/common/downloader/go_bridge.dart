import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// 与 Go 下载后端通信的桥接层。
class DownloadServerBridge {
  static final DownloadServerBridge _instance = DownloadServerBridge._internal();
  factory DownloadServerBridge() => _instance;
  DownloadServerBridge._internal();

  static const _channel = MethodChannel('pan123next/downloader');

  Process? _process;
  int _port = 0;
  bool _running = false;

  int get port => _port;
  bool get isRunning => _running;

  // ---- Windows Job Object: 父进程被强制终止时自动杀死子进程 ----
  static DynamicLibrary? _kernel32;
  static Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>)? _createJobObjectW;
  static int Function(Pointer<Void>, int, Pointer<Void>, int)? _setInformationJobObject;
  static Pointer<Void> Function(int, int, int)? _openProcess;
  static int Function(Pointer<Void>, Pointer<Void>)? _assignProcessToJobObject;
  static int Function(Pointer<Void>)? _closeHandle;

  Pointer<Void>? _jobHandle;

  static void _ensureWin32() {
    if (_kernel32 != null) return;
    _kernel32 = DynamicLibrary.open('kernel32.dll');
    _createJobObjectW = _kernel32!.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>),
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>)>('CreateJobObjectW');
    _setInformationJobObject = _kernel32!.lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int, Pointer<Void>, int)>('SetInformationJobObject');
    _openProcess = _kernel32!.lookupFunction<
        Pointer<Void> Function(Uint32, Int32, Uint32),
        Pointer<Void> Function(int, int, int)>('OpenProcess');
    _assignProcessToJobObject = _kernel32!.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>),
        int Function(Pointer<Void>, Pointer<Void>)>('AssignProcessToJobObject');
    _closeHandle = _kernel32!.lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('CloseHandle');
  }

  void _createJobObject() {
    _ensureWin32();
    _jobHandle = _createJobObjectW!(nullptr, nullptr);
    if (_jobHandle == nullptr) return;

    // JOBOBJECT_EXTENDED_LIMIT_INFORMATION (x64 layout: 120 bytes)
    // Offset 16: BasicLimitInformation.LimitFlags (DWORD)
    const jobObjectExtendedLimitInformation = 9;
    const jobObjectLimitKillOnJobClose = 0x00002000;

    final info = calloc<Uint8>(120);
    (info + 16).cast<Uint32>().value = jobObjectLimitKillOnJobClose;

    final ok = _setInformationJobObject!(
          _jobHandle!,
          jobObjectExtendedLimitInformation,
          info.cast<Void>(),
          120,
        ) !=
        0;

    calloc.free(info);

    if (!ok) {
      _closeHandle!(_jobHandle!);
      _jobHandle = nullptr;
    }
  }

  void _assignProcessToJob(int pid) {
    if (_jobHandle == nullptr) return;
    _ensureWin32();

    const processSetQuota = 0x0200;
    const processTerminate = 0x0001;

    final ph = _openProcess!(processSetQuota | processTerminate, 0, pid);
    if (ph == nullptr) return;

    _assignProcessToJobObject!(_jobHandle!, ph);
    _closeHandle!(ph);
  }

  void _closeJobObject() {
    if (_jobHandle == nullptr) return;
    _ensureWin32();
    _closeHandle!(_jobHandle!);
    _jobHandle = nullptr;
  }

  Future<bool> start({String dataDir = ''}) async {
    if (_running) return true;
    if (Platform.isAndroid || Platform.isIOS) return _startMobile(dataDir);
    return _startDesktop(dataDir);
  }

  Future<void> stop() async {
    if (!_running) return;
    if (Platform.isAndroid || Platform.isIOS) {
      try { await _channel.invokeMethod('stopServer'); } catch (_) {}
    } else {
      _killProcess();
    }
    _running = false;
    _port = 0;
  }

  // ---- 桌面端 ----

  Future<bool> _startDesktop(String dataDir) async {
    try {
      // Windows: 创建 Job Object，父进程退出时自动终止子进程
      if (Platform.isWindows) _createJobObject();

      _process = await _startProcess(dataDir);
      if (_process == null) return false;

      // Windows: 将子进程关联到 Job Object
      if (Platform.isWindows) _assignProcessToJob(_process!.pid);

      final line = await _process!.stdout
          .transform(utf8.decoder)
          .first
          .timeout(const Duration(seconds: 5));

      _port = int.tryParse(line.trim()) ?? 0;
      if (_port <= 0) { _killProcess(); return false; }

      _running = true;
      _process!.exitCode.then((_) { _running = false; _port = 0; });
      return true;
    } catch (e) {
      _killProcess();
      return false;
    }
  }

  void _killProcess() {
    if (_process != null) {
      if (Platform.isWindows) { _process!.kill(); }
      else { _process!.kill(ProcessSignal.sigterm); }
      _process = null;
    }
    if (Platform.isWindows) _closeJobObject();
  }

  Future<Process?> _startProcess(String dataDir) async {
    final name = Platform.isWindows ? 'downloader_server.exe' : 'downloader_server';
    for (final path in _binaryPaths(name)) {
      if (File(path).existsSync()) {
        final args = dataDir.isNotEmpty ? <String>['--data-dir', dataDir] : <String>[];
        return await Process.start(path, args, runInShell: false);
      }
    }
    return null;
  }

  List<String> _binaryPaths(String name) => [
    // 1. Same dir as Flutter exe (release bundle: install copies it there)
    if (Platform.resolvedExecutable.isNotEmpty)
      '${Directory(Platform.resolvedExecutable).parent.path}/$name',
    // 2. CMake build root (debug: .../build/windows/x64/ if exe is .../runner/Debug/)
    if (Platform.resolvedExecutable.isNotEmpty)
      '${Directory(Platform.resolvedExecutable).parent.parent.parent.path}/$name',
    // 3. CWD, source tree, build output
    name,
    'server/cmd/server/$name',
    'build/go/$name',
  ];

  // ---- 移动端 ----

  Future<bool> _startMobile(String dataDir) async {
    try {
      final result = await _channel.invokeMethod<int>('startServer', {'dataDir': dataDir});
      if (result == null || result <= 0) return false;
      _port = result;
      _running = true;
      return true;
    } catch (_) { return false; }
  }
}

/// HTTP 客户端，所有请求带 5 秒超时。
class DownloadServerClient {
  final int port;
  DownloadServerClient(this.port);

  String get _base => 'http://127.0.0.1:$port/api';

  Future<Map<String, dynamic>?> addTask({
    required String url, required String savePath, String? fileName,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url, 'save_path': savePath, 'file_name': fileName ?? ''}),
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> listTasks() async {
    try {
      final resp = await http.get(Uri.parse('$_base/tasks'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> pauseTask(String id) async {
    try {
      final resp = await http.post(Uri.parse('$_base/tasks/$id/pause'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> resumeTask(String id) async {
    try {
      final resp = await http.post(Uri.parse('$_base/tasks/$id/resume'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> removeTask(String id) async {
    try {
      final resp = await http.delete(Uri.parse('$_base/tasks/$id/remove'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> clearCompleted() async {
    try {
      final resp = await http.post(Uri.parse('$_base/tasks/completed'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }

  Stream<List<Map<String, dynamic>>> pollProgress({
    Duration interval = const Duration(milliseconds: 700),
  }) async* {
    while (true) {
      await Future.delayed(interval);
      try {
        final tasks = await listTasks();
        yield tasks;
      } catch (_) {
        yield [];
      }
    }
  }
}
