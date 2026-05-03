import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:pan123next/common/get_platform.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 对桌面端标题栏自定义
  if (isDesktop()) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    // 窗口显示之前将上边的显示参数应用到组件
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
    });
  }

  await UserDb().initDb();
  await AppDb().initDb();
  await DownloaderDb().initDb();

  await DownloadSession().initialize();

  Get.put(AppSession());

  runApp(const MainApp());
}
