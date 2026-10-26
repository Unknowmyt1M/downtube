import 'package:flutter_test/flutter_test.dart';
import 'package:downtube/domain/entities/media_item.dart';
import 'package:downtube/data/models/media_item_model.dart';

void main() {
  group('MediaItem Model & Entity Tests', () {
    final testDate = DateTime(2026, 10, 26, 12, 0, 0);

    test('serializes to JSON correctly', () {
      final item = MediaItem(
        id: '12345',
        displayName: 'Sample Video.mp4',
        uri: '/storage/emulated/0/Download/Sample.mp4',
        sizeBytes: 15485760,
        mimeType: 'video/mp4',
        dateAdded: testDate,
        availability: MediaAvailability.available,
      );

      final json = MediaItemModel.toJson(item);

      expect(json['id'], equals('12345'));
      expect(json['displayName'], equals('Sample Video.mp4'));
      expect(json['uri'], equals('/storage/emulated/0/Download/Sample.mp4'));
      expect(json['sizeBytes'], equals(15485760));
      expect(json['mimeType'], equals('video/mp4'));
      expect(json['availability'], equals('available'));
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': '999',
        'displayName': 'Test Video.webm',
        'uri': '/path/to/test.webm',
        'mimeType': 'video/webm',
        'sizeBytes': 2048,
        'dateAdded': testDate.toIso8601String(),
        'availability': 'missing',
      };

      final item = MediaItemModel.fromJson(json);

      expect(item.id, equals('999'));
      expect(item.displayName, equals('Test Video.webm'));
      expect(item.mimeType, equals('video/webm'));
      expect(item.availability, equals(MediaAvailability.missing));
    });

    test('sorting orders items by name, size, and date', () {
      final item1 = MediaItem(
        id: '1',
        displayName: 'Bravo.mp4',
        uri: '/path/1',
        sizeBytes: 100,
        dateAdded: DateTime(2026, 1, 1),
      );
      final item2 = MediaItem(
        id: '2',
        displayName: 'Alpha.mp4',
        uri: '/path/2',
        sizeBytes: 500,
        dateAdded: DateTime(2026, 2, 1),
      );

      final list = [item1, item2];

      // Sort by Name (A-Z)
      final sortedByName = List<MediaItem>.from(list)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      expect(sortedByName.first.displayName, equals('Alpha.mp4'));

      // Sort by Size (Desc)
      final sortedBySize = List<MediaItem>.from(list)
        ..sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
      expect(sortedBySize.first.displayName, equals('Alpha.mp4'));

      // Sort by Date (Desc)
      final sortedByDate = List<MediaItem>.from(list)
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      expect(sortedByDate.first.displayName, equals('Alpha.mp4'));
    });
  });
}
