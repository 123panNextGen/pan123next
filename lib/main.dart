import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:pan123next/common/get_platform.dart';

import 'app.dart';

class _GoProcessCleanup extends WindowListener {
  final DownloadSession _session;
  _GoProcessCleanup(this._session);
  @override
  void onWindowClose() => _session.stopServer();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop()) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      // size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {});
  }

  final appDb = AppDb();
  final userDb = UserDb();
  final downloaderDb = DownloaderDb();

  await appDb.initDb();
  await userDb.initDb();
  await downloaderDb.initDb();

  Get.put(appDb);
  Get.put(userDb);
  Get.put(downloaderDb);
  Get.put(NetSession());

  final downloadSession = DownloadSession();
  Get.put(downloadSession);

  // 窗口关闭时终止 Go 进程
  if (isDesktop()) {
    windowManager.addListener(_GoProcessCleanup(downloadSession));
  }

  await downloadSession.startServer();

  // 终端信号：Ctrl+C / SIGTERM 时终止 Go 进程
  ProcessSignal.sigint.watch().listen((_) => downloadSession.stopServer());
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => downloadSession.stopServer());
  }

  Get.put(AppSession());

  runApp(const MainApp());
}
