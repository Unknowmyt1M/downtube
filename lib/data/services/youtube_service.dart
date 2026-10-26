import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/youtube_url_parser.dart';
import '../../domain/entities/youtube_video.dart';

class YouTubeService {
  final Dio _dio;

  YouTubeService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  /// Fetches legitimate video metadata using YouTube's official oEmbed endpoint.
  /// Does not require an API key and operates within official terms.
  Future<YouTubeVideo> fetchVideoDetails(String videoId) async {
    final watchUrl = YouTubeUrlParser.normalizeToWatchUrl(videoId);
    final oEmbedUrl =
        'https://www.youtube.com/oembed?url=${Uri.encodeComponent(watchUrl)}&format=json';

    try {
      final response = await _dio.get(oEmbedUrl);
      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        return YouTubeVideo(
          id: videoId,
          title: data['title'] as String? ?? 'YouTube Video',
          authorName: data['author_name'] as String? ?? 'YouTube Creator',
          authorUrl: data['author_url'] as String? ?? '',
          thumbnailUrl:
              data['thumbnail_url'] as String? ??
              YouTubeUrlParser.getThumbnailUrl(videoId),
          originalUrl: watchUrl,
        );
      } else {
        throw const PlaybackUnavailableFailure(
          'This video could not be loaded or is private/unavailable.',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkUnavailableFailure(
          'Unable to connect. Check your internet connection.',
        );
      }
      if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
        throw const InvalidUrlFailure('Video not found or URL is invalid.');
      }
      // If oEmbed blocked or limited, return basic fallback with official thumbnail
      return YouTubeVideo(
        id: videoId,
        title: 'YouTube Video ($videoId)',
        authorName: 'YouTube',
        authorUrl: 'https://www.youtube.com',
        thumbnailUrl: YouTubeUrlParser.getThumbnailUrl(videoId),
        originalUrl: watchUrl,
      );
    } catch (_) {
      throw const PlaybackUnavailableFailure('Failed to load video metadata.');
    }
  }
}
