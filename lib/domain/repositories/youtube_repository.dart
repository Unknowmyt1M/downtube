import '../entities/youtube_video.dart';

abstract class YouTubeRepository {
  /// Retrieves legitimate video details for a given YouTube video ID.
  /// Throws typed [AppFailure] (e.g. [InvalidUrlFailure], [NetworkUnavailableFailure], [PlaybackUnavailableFailure]).
  /// Guarantees: Never exposes or fabricates direct stream download URLs.
  Future<YouTubeVideo> getVideoDetails(String videoId);
}
