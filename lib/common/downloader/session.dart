import 'dart:async';
import 'package:get/get.dart';
import 'package:pan123next/common/api/model.dart';
import 'model.dart';

class DownloadSession extends GetxController {
  static final DownloadSession _instance = DownloadSession._internal();
  factory DownloadSession() => _instance;
  DownloadSession._internal();

  final List<DownloadItemModel> _downloadList = [];

  final StreamController<DownloadItemModel> _progressController =
      StreamController.broadcast();
  final StreamController<List<DownloadItemModel>> _listController =
      StreamController.broadcast();

  final bool _running = false;

  Stream<DownloadItemModel> get progressStream => _progressController.stream;
  Stream<List<DownloadItemModel>> get listStream => _listController.stream;
  List<DownloadItemModel> get downloadList => List.unmodifiable(_downloadList);
  bool get isRunning => _running;
  int get port => 0;

  UserInfoModel? get userInformation => null;

  void setUserInformation(UserInfoModel userInfo) {}
  void updateUserInfo(UserInfoModel userInfo) {}

  Future<bool> startServer() async => false;

  Future<void> stopServer() async {}

  Future<DownloadItemModel?> addDownload({
    required FileItemModel file,
    required String downloadUrl,
    required String savePath,
  }) async => null;

  Future<bool> pauseDownload(DownloadItemModel item) async => false;

  Future<bool> resumeDownload(DownloadItemModel item) async => false;

  Future<bool> removeDownload(DownloadItemModel item) async => false;

  Future<bool> clearCompleted() async => false;
}
