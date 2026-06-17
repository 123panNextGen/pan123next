import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:fluent_ui/fluent_ui.dart';

bool isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

bool isMobile() {
  return !isDesktop();
}

bool isApple() {
  return Platform.isMacOS || Platform.isIOS;
}

bool isSupportedAria() {
  return Platform.isWindows || Platform.isLinux || Platform.isAndroid;
}

String getPlatform() {
  if (isDesktop()) {
    return 'desktop';
  } else if (isMobile()) {
    return 'mobile';
  } else {
    return 'unknown';
  }
}

String getSystem() {
  if (Platform.isWindows) {
    return 'windows';
  } else if (Platform.isLinux) {
    return 'linux';
  } else if (Platform.isMacOS) {
    return 'macos';
  } else if (Platform.isIOS) {
    return 'ios';
  } else if (Platform.isAndroid) {
    return 'android';
  } else {
    return 'unknown';
  }
}

PaneDisplayMode getPaneDisplayMode() {
  return isDesktop() ? PaneDisplayMode.compact : PaneDisplayMode.auto;
}

Future<String> getVersion() async {
  // 获取 pubspec.yaml 中的版本号
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
