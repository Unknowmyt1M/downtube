import 'package:flutter_test/flutter_test.dart';
import 'package:downtube/data/services/direct_download_provider.dart';
import 'package:downtube/domain/entities/download_task.dart';
import 'package:downtube/data/models/download_task_model.dart';

void main() {
  group('Download Provider & Task Tests', () {
    final provider = DirectFileDownloadProvider();

    test(
      'explicitly rejects YouTube URLs to comply with official terms and PRD principles',
      () {
        expect(
          provider.supports('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          isFalse,
        );
        expect(provider.supports('https://youtu.be/dQw4w9WgXcQ'), isFalse);
        expect(
          provider.supports('https://m.youtube.com/shorts/dQw4w9WgXcQ'),
          isFalse,
        );
      },
    );

    test('supports authorized direct media file URLs', () {
      expect(
        provider.supports('https://archive.org/download/test/video.mp4'),
        isTrue,
      );
      expect(provider.supports('http://example.com/media/clip.webm'), isTrue);
      expect(provider.supports('https://cdn.site.com/movie.mkv'), isTrue);
    });

    test('rejects non-video and malformed URLs', () {
      expect(provider.supports('https://example.com/image.png'), isFalse);
      expect(provider.supports('ftp://example.com/video.mp4'), isFalse);
      expect(provider.supports('invalid_string'), isFalse);
    });

    test('DownloadTask computes progress accurately', () {
      final now = DateTime(2026, 10, 26);
      final task = DownloadTask(
        id: '1',
        sourceType: 'direct',
        sourceReference: 'https://example.com/test.mp4',
        displayName: 'test.mp4',
        bytesReceived: 50,
        totalBytes: 100,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.progress, equals(0.5));
    });

    test('DownloadTask JSON serialization round-trips correctly', () {
      final now = DateTime(2026, 10, 26, 15, 30);
      final task = DownloadTask(
        id: 'task_007',
        sourceType: 'authorized_direct_file',
        sourceReference: 'https://example.com/sample.mp4',
        displayName: 'Sample Video',
        status: DownloadTaskStatus.downloading,
        bytesReceived: 1024,
        totalBytes: 2048,
        createdAt: now,
        updatedAt: now,
      );

      final json = DownloadTaskModel.toJson(task);
      final deserialized = DownloadTaskModel.fromJson(json);

      expect(deserialized.id, equals('task_007'));
      expect(deserialized.status, equals(DownloadTaskStatus.downloading));
      expect(deserialized.bytesReceived, equals(1024));
      expect(deserialized.totalBytes, equals(2048));
    });
  });
}
