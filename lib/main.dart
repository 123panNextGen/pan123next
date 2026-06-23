import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:pan123next/common/get_platform.dart';

import 'app.dart';

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

  Get.put(AppSession());

  runApp(const MainApp());
}
