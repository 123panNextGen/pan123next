import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/extra.dart';
import 'package:window_manager/window_manager.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
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
  final neoDb = await NeoDb.create();

  await appDb.initDb();

  Get.put(appDb);
  Get.put(neoDb);
  Get.put(NetSession());
  Get.put(ExtraApiService());

  Get.put(AppSession());

  runApp(const MainApp());
}
