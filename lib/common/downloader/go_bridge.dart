import 'dart:async';

class DownloadServerBridge {
  DownloadServerBridge();

  bool get isRunning => false;
  int get port => 0;

  Future<bool> start({String dataDir = ''}) async => false;

  Future<bool> stop() async => false;
}

class DownloadServerClient {
  DownloadServerClient(int port);

  Future<Map<String, dynamic>?> addTask({
    required String url,
    required String savePath,
    required String fileName,
  }) async => null;

  Future<bool> pauseTask(String id) async => false;

  Future<bool> resumeTask(String id) async => false;

  Future<bool> removeTask(String id) async => false;

  Future<bool> clearCompleted() async => false;

  Future<List<Map<String, dynamic>>> listTasks() async => [];

  Stream<List<Map<String, dynamic>>> pollProgress({Duration? interval}) =>
      Stream.empty();
}
