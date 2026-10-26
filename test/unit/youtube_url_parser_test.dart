import 'package:flutter_test/flutter_test.dart';
import 'package:downtube/core/utils/youtube_url_parser.dart';

void main() {
  group('YouTubeUrlParser Tests', () {
    const validVideoId = 'dQw4w9WgXcQ';

    test('extracts video ID from standard watch URL', () {
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://www.youtube.com/watch?v=$validVideoId',
        ),
        equals(validVideoId),
      );
      expect(
        YouTubeUrlParser.extractVideoId(
          'http://youtube.com/watch?v=$validVideoId',
        ),
        equals(validVideoId),
      );
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://m.youtube.com/watch?v=$validVideoId',
        ),
        equals(validVideoId),
      );
    });

    test('extracts video ID from watch URL with extra query parameters', () {
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://www.youtube.com/watch?v=$validVideoId&t=42s&feature=share',
        ),
        equals(validVideoId),
      );
    });

    test('extracts video ID from shortened youtu.be URL', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://youtu.be/$validVideoId'),
        equals(validVideoId),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://youtu.be/$validVideoId?t=10'),
        equals(validVideoId),
      );
    });

    test('extracts video ID from YouTube Shorts URL', () {
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://www.youtube.com/shorts/$validVideoId',
        ),
        equals(validVideoId),
      );
    });

    test('extracts video ID from YouTube Embed URL', () {
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://www.youtube.com/embed/$validVideoId',
        ),
        equals(validVideoId),
      );
    });

    test('extracts video ID from YouTube Live URL', () {
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://www.youtube.com/live/$validVideoId',
        ),
        equals(validVideoId),
      );
    });

    test('extracts video ID directly from 11-char alphanumeric ID', () {
      expect(
        YouTubeUrlParser.extractVideoId(validVideoId),
        equals(validVideoId),
      );
    });

    test('rejects unsupported domains and malformed URLs', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://vimeo.com/12345678'),
        isNull,
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://facebook.com/watch?v=123'),
        isNull,
      );
      expect(YouTubeUrlParser.extractVideoId('not a url'), isNull);
      expect(YouTubeUrlParser.extractVideoId(''), isNull);
      expect(YouTubeUrlParser.extractVideoId('   '), isNull);
      expect(
        YouTubeUrlParser.extractVideoId('https://youtube.com/watch?v='),
        isNull,
      );
      expect(
        YouTubeUrlParser.extractVideoId(
          'https://youtube.com/watch?v=too_short',
        ),
        isNull,
      );
    });

    test('normalizes video ID to clean watch URL', () {
      expect(
        YouTubeUrlParser.normalizeToWatchUrl(validVideoId),
        equals('https://www.youtube.com/watch?v=$validVideoId'),
      );
    });

    test('generates canonical thumbnail URL', () {
      expect(
        YouTubeUrlParser.getThumbnailUrl(validVideoId),
        equals('https://img.youtube.com/vi/$validVideoId/hqdefault.jpg'),
      );
    });
  });
}
