import '../entities/media_item.dart';

abstract class MediaLibraryRepository {
  /// Imports a video file selected via Storage Access Framework / file picker
  Future<MediaItem> importFromLocalUri({
    required String uri,
    required String displayName,
    int? sizeBytes,
    String? mimeType,
  });

  /// Lists all library media items with sorting applied
  Future<List<MediaItem>> listMedia({
    MediaSortBy sortBy = MediaSortBy.dateAdded,
  });

  /// Gets single media item by id
  Future<MediaItem?> getMedia(String id);

  /// Removes an entry from the library metadata without physically deleting the underlying file
  Future<void> removeLibraryEntry(String id);

  /// Permanently deletes physical file and removes from library
  Future<bool> deletePhysicalFile(String id);

  /// Verifies existence and availability of files in the library
  Future<void> verifyAvailability();
}
