import 'dart:io';
import '../../core/errors/failures.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/media_library_repository.dart';
import '../storage/app_storage.dart';

class MediaLibraryRepositoryImpl implements MediaLibraryRepository {
  final AppStorage _storage;

  MediaLibraryRepositoryImpl(this._storage);

  @override
  Future<MediaItem> importFromLocalUri({
    required String uri,
    required String displayName,
    int? sizeBytes,
    String? mimeType,
  }) async {
    try {
      int? calculatedSize = sizeBytes;
      if (calculatedSize == null || calculatedSize <= 0) {
        final file = File(uri);
        if (await file.exists()) {
          calculatedSize = await file.length();
        }
      }

      final item = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: displayName,
        uri: uri,
        sizeBytes: calculatedSize,
        mimeType: mimeType ?? 'video/mp4',
        dateAdded: DateTime.now(),
        availability: MediaAvailability.available,
      );

      final current = _storage.getMediaItems();
      current.insert(0, item);
      await _storage.saveMediaItems(current);

      return item;
    } catch (e) {
      throw StorageFailure('Failed to import media file: $e');
    }
  }

  @override
  Future<List<MediaItem>> listMedia({
    MediaSortBy sortBy = MediaSortBy.dateAdded,
  }) async {
    final items = _storage.getMediaItems();

    // Verify availability for local file paths
    final updated = items.map((item) {
      if (item.uri.startsWith('/')) {
        final exists = File(item.uri).existsSync();
        return item.copyWith(
          availability: exists
              ? MediaAvailability.available
              : MediaAvailability.missing,
        );
      }
      return item;
    }).toList();

    // Sort items
    switch (sortBy) {
      case MediaSortBy.dateAdded:
        updated.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case MediaSortBy.name:
        updated.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
        break;
      case MediaSortBy.size:
        updated.sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
        break;
    }

    return updated;
  }

  @override
  Future<MediaItem?> getMedia(String id) async {
    final items = _storage.getMediaItems();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removeLibraryEntry(String id) async {
    final items = _storage.getMediaItems();
    items.removeWhere((item) => item.id == id);
    await _storage.saveMediaItems(items);
  }

  @override
  Future<bool> deletePhysicalFile(String id) async {
    final items = _storage.getMediaItems();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final item = items[index];
    var fileDeleted = false;

    try {
      final file = File(item.uri);
      if (await file.exists()) {
        await file.delete();
        fileDeleted = true;
      }
    } catch (_) {
      // Permission or SAF constraint prevented direct file deletion
    }

    items.removeAt(index);
    await _storage.saveMediaItems(items);
    return fileDeleted;
  }

  @override
  Future<void> verifyAvailability() async {
    final items = _storage.getMediaItems();
    var changed = false;

    final updated = items.map((item) {
      if (item.uri.startsWith('/')) {
        final exists = File(item.uri).existsSync();
        final newAvail = exists
            ? MediaAvailability.available
            : MediaAvailability.missing;
        if (newAvail != item.availability) {
          changed = true;
          return item.copyWith(availability: newAvail);
        }
      }
      return item;
    }).toList();

    if (changed) {
      await _storage.saveMediaItems(updated);
    }
  }
}
