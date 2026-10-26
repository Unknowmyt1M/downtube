import 'package:flutter/foundation.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/media_library_repository.dart';
import '../../data/storage/app_storage.dart';

class LibraryController extends ChangeNotifier {
  final MediaLibraryRepository _repository;
  final AppStorage _storage;

  List<MediaItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  MediaSortBy _sortBy = MediaSortBy.dateAdded;

  LibraryController({
    required MediaLibraryRepository repository,
    required AppStorage storage,
  }) : _repository = repository,
       _storage = storage {
    _sortBy = _storage.getSortBy();
    loadItems();
  }

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MediaSortBy get sortBy => _sortBy;

  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.listMedia(sortBy: _sortBy);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSortBy(MediaSortBy newSort) async {
    if (_sortBy == newSort) return;
    _sortBy = newSort;
    await _storage.setSortBy(newSort);
    await loadItems();
  }

  Future<MediaItem> importVideo({
    required String path,
    required String name,
    int? size,
    String? mimeType,
  }) async {
    final item = await _repository.importFromLocalUri(
      uri: path,
      displayName: name,
      sizeBytes: size,
      mimeType: mimeType,
    );
    await loadItems();
    return item;
  }

  Future<void> removeEntry(String id) async {
    await _repository.removeLibraryEntry(id);
    await loadItems();
  }

  Future<bool> deletePhysicalFile(String id) async {
    final deleted = await _repository.deletePhysicalFile(id);
    await loadItems();
    return deleted;
  }

  Future<void> refresh() async {
    await _repository.verifyAvailability();
    await loadItems();
  }
}
