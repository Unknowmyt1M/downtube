import '../../domain/entities/media_item.dart';

class MediaItemModel {
  static Map<String, dynamic> toJson(MediaItem item) {
    return {
      'id': item.id,
      'displayName': item.displayName,
      'uri': item.uri,
      'mimeType': item.mimeType,
      'sizeBytes': item.sizeBytes,
      'durationMs': item.durationMs,
      'thumbnailReference': item.thumbnailReference,
      'dateAdded': item.dateAdded.toIso8601String(),
      'availability': item.availability.name,
    };
  }

  static MediaItem fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Untitled Video',
      uri: json['uri'] as String,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      durationMs: json['durationMs'] as int?,
      thumbnailReference: json['thumbnailReference'] as String?,
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      availability: json['availability'] == 'missing'
          ? MediaAvailability.missing
          : MediaAvailability.available,
    );
  }
}
