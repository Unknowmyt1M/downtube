import '../../core/errors/failures.dart';
import '../../core/utils/youtube_url_parser.dart';
import '../../domain/entities/youtube_video.dart';
import '../../domain/repositories/youtube_repository.dart';
import '../services/youtube_service.dart';

class YouTubeRepositoryImpl implements YouTubeRepository {
  final YouTubeService _service;

  YouTubeRepositoryImpl({YouTubeService? service})
    : _service = service ?? YouTubeService();

  @override
  Future<YouTubeVideo> getVideoDetails(String videoId) async {
    final cleanId = YouTubeUrlParser.extractVideoId(videoId);
    if (cleanId == null) {
      throw const InvalidUrlFailure(
        'Invalid YouTube video ID or link provided.',
      );
    }
    return _service.fetchVideoDetails(cleanId);
  }
}
