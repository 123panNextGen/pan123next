import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

bool isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

bool isMobile() {
  return !isDesktop();
}

PaneDisplayMode getPaneDisplayMode() {
  return isDesktop() ? PaneDisplayMode.compact : PaneDisplayMode.auto;
}
