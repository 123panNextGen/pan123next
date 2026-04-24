import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, String>> getVersionInfo() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String version = packageInfo.version; // 例如: "1.0.0"
  String buildNumber = packageInfo.buildNumber; // 例如: "1"
  String appName = packageInfo.appName; // 应用名称
  String packageName = packageInfo.packageName; // 包名

  return {
    'version': version,
    'buildNumber': buildNumber,
    'appName': appName,
    'packageName': packageName,
  };
}
