import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pan123next/common/downloader/download_task.dart';

class DownloadStore {
  static const _key = 'downloader.tasks';

  Future<void> saveTasks(List<DownloadTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_key, json);
  }

  Future<void> saveTask(DownloadTask task) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await saveTasks(tasks);
  }

  Future<List<DownloadTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => DownloadTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> removeTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
