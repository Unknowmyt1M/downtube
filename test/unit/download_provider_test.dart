import 'package:flutter_test/flutter_test.dart';
import 'package:downtube/data/services/direct_download_provider.dart';
import 'package:downtube/data/services/yt_dlp_download_provider.dart';
import 'package:downtube/domain/entities/download_task.dart';
import 'package:downtube/data/models/download_task_model.dart';

void main() {
  group('Download Provider & Task Tests', () {
    final directProvider = DirectFileDownloadProvider();
    final ytdlpProvider = YtDlpDownloadProvider();

    test('DirectFileDownloadProvider rejects YouTube URLs', () {
      expect(
        directProvider.supports('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isFalse,
      );
      expect(directProvider.supports('https://youtu.be/dQw4w9WgXcQ'), isFalse);
    });

    test('YtDlpDownloadProvider supports YouTube and video URLs', () {
      expect(
        ytdlpProvider.supports('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
      expect(ytdlpProvider.supports('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(ytdlpProvider.supports('https://example.com/video.mp4'), isTrue);
      expect(ytdlpProvider.supports('invalid_url'), isFalse);
    });

    test('supports authorized direct media file URLs', () {
      expect(
        directProvider.supports('https://archive.org/download/test/video.mp4'),
        isTrue,
      );
      expect(
        directProvider.supports('http://example.com/media/clip.webm'),
        isTrue,
      );
      expect(directProvider.supports('https://cdn.site.com/movie.mkv'), isTrue);
    });

    test('rejects non-video and malformed URLs', () {
      expect(directProvider.supports('https://example.com/image.png'), isFalse);
      expect(directProvider.supports('ftp://example.com/video.mp4'), isFalse);
      expect(directProvider.supports('invalid_string'), isFalse);
    });

    test('DownloadTask computes progress accurately', () {
      final now = DateTime(2026, 10, 26);
      final task = DownloadTask(
        id: '1',
        sourceType: 'yt_dlp_engine',
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
        sourceType: 'yt_dlp_engine',
        sourceReference: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
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
