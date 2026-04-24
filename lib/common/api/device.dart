import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> loadDeviceData() async {
  final String response = await rootBundle.loadString(
    'assets/data/device.json',
  );
  final data = jsonDecode(response);
  return data;
}

Future<Map<dynamic, dynamic>> getRandomDevice() async {
  final deviceData = await loadDeviceData();
  final Random random = Random();

  final deviceTypes = List<String>.from(deviceData['type']);
  final deviceType = deviceTypes[random.nextInt(deviceTypes.length)];
  final osTypes = List<String>.from(deviceData['os']);
  final osVersion = osTypes[random.nextInt(osTypes.length)];

  return {'type': deviceType, 'os': osVersion};
}
