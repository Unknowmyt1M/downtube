enum MediaAvailability { available, missing }

enum MediaSortBy { dateAdded, name, size }

class MediaItem {
  final String id;
  final String displayName;
  final String uri;
  final String? mimeType;
  final int? sizeBytes;
  final int? durationMs;
  final String? thumbnailReference;
  final DateTime dateAdded;
  final MediaAvailability availability;

  const MediaItem({
    required this.id,
    required this.displayName,
    required this.uri,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.thumbnailReference,
    required this.dateAdded,
    this.availability = MediaAvailability.available,
  });

  MediaItem copyWith({
    String? id,
    String? displayName,
    String? uri,
    String? mimeType,
    int? sizeBytes,
    int? durationMs,
    String? thumbnailReference,
    DateTime? dateAdded,
    MediaAvailability? availability,
  }) {
    return MediaItem(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      uri: uri ?? this.uri,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      thumbnailReference: thumbnailReference ?? this.thumbnailReference,
      dateAdded: dateAdded ?? this.dateAdded,
      availability: availability ?? this.availability,
    );
  }
}
