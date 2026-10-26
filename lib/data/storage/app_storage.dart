import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';
import '../models/media_item_model.dart';
import '../models/download_task_model.dart';

class AppStorage {
  static const String _keyMediaItems = 'downtube_media_items';
  static const String _keyDownloadTasks = 'downtube_download_tasks';
  static const String _keySortBy = 'downtube_sort_by';
  static const String _keyRecentUrls = 'downtube_recent_urls';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  static Future<AppStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  // --- Media Items ---
  List<MediaItem> getMediaItems() {
    final raw = _prefs.getStringList(_keyMediaItems) ?? [];
    final items = <MediaItem>[];
    for (final jsonStr in raw) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        items.add(MediaItemModel.fromJson(map));
      } catch (_) {
        // Skip corrupted entries gracefully
      }
    }
    return items;
  }

  Future<void> saveMediaItems(List<MediaItem> items) async {
    final raw = items
        .map((item) => jsonEncode(MediaItemModel.toJson(item)))
        .toList();
    await _prefs.setStringList(_keyMediaItems, raw);
  }

  // --- Download Tasks ---
  List<DownloadTask> getDownloadTasks() {
    final raw = _prefs.getStringList(_keyDownloadTasks) ?? [];
    final tasks = <DownloadTask>[];
    for (final jsonStr in raw) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        tasks.add(DownloadTaskModel.fromJson(map));
      } catch (_) {
        // Skip corrupted entries gracefully
      }
    }
    return tasks;
  }

  Future<void> saveDownloadTasks(List<DownloadTask> tasks) async {
    final raw = tasks
        .map((task) => jsonEncode(DownloadTaskModel.toJson(task)))
        .toList();
    await _prefs.setStringList(_keyDownloadTasks, raw);
  }

  // --- Preferences ---
  MediaSortBy getSortBy() {
    final index = _prefs.getInt(_keySortBy);
    if (index != null && index >= 0 && index < MediaSortBy.values.length) {
      return MediaSortBy.values[index];
    }
    return MediaSortBy.dateAdded;
  }

  Future<void> setSortBy(MediaSortBy sortBy) async {
    await _prefs.setInt(_keySortBy, sortBy.index);
  }

  List<String> getRecentUrls() {
    return _prefs.getStringList(_keyRecentUrls) ?? [];
  }

  Future<void> addRecentUrl(String url) async {
    final list = getRecentUrls();
    list.remove(url);
    list.insert(0, url);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await _prefs.setStringList(_keyRecentUrls, list);
  }

  Future<void> clearRecentUrls() async {
    await _prefs.remove(_keyRecentUrls);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
