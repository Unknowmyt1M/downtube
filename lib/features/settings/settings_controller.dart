import 'package:flutter/foundation.dart';
import '../../domain/entities/media_item.dart';
import '../../data/storage/app_storage.dart';

class SettingsController extends ChangeNotifier {
  final AppStorage _storage;

  SettingsController({required AppStorage storage}) : _storage = storage;

  MediaSortBy get sortBy => _storage.getSortBy();
  List<String> get recentUrls => _storage.getRecentUrls();

  Future<void> updateSortBy(MediaSortBy sort) async {
    await _storage.setSortBy(sort);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storage.clearRecentUrls();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _storage.clearAll();
    notifyListeners();
  }
}
