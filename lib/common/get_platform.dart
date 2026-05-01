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

PaneDisplayMode getPaneDisplayMode() {
  return isDesktop() ? PaneDisplayMode.compact : PaneDisplayMode.auto;
}

Future<String> getVersion() async {
  // 获取 pubspec.yaml 中的版本号
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}