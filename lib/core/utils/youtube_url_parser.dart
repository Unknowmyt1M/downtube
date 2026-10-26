class YouTubeUrlParser {
  YouTubeUrlParser._();

  // Supported hosts: youtube.com, www.youtube.com, m.youtube.com, youtu.be, music.youtube.com
  static final RegExp _videoIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Parses any valid YouTube URL or direct 11-char video ID and returns the video ID.
  /// Returns `null` if invalid, unrelated domain, or ID cannot be extracted.
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Check if input itself is directly an 11-character video ID
    if (_videoIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
      if (!uri.hasScheme) {
        uri = Uri.parse('https://$trimmed');
      }
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();

    // Check shortened youtu.be domain
    if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final candidate = segments.first;
        if (_videoIdRegex.hasMatch(candidate)) {
          return candidate;
        }
      }
      return null;
    }

    // Check youtube.com domains (www.youtube.com, m.youtube.com, music.youtube.com)
    final isYouTubeDomain =
        host == 'youtube.com' || host.endsWith('.youtube.com');

    if (!isYouTubeDomain) {
      return null;
    }

    // Standard watch URL: /watch?v=VIDEO_ID
    if (uri.path == '/watch' || uri.path.startsWith('/watch/')) {
      final v = uri.queryParameters['v'];
      if (v != null && _videoIdRegex.hasMatch(v)) {
        return v;
      }
    }

    // Shorts URL: /shorts/VIDEO_ID
    if (uri.pathSegments.contains('shorts')) {
      final index = uri.pathSegments.indexOf('shorts');
      if (index + 1 < uri.pathSegments.length) {
        final candidate = uri.pathSegments[index + 1];
        if (_videoIdRegex.hasMatch(candidate)) {
          return candidate;
        }
      }
    }

    // Embed URL: /embed/VIDEO_ID
    if (uri.pathSegments.contains('embed')) {
      final index = uri.pathSegments.indexOf('embed');
      if (index + 1 < uri.pathSegments.length) {
        final candidate = uri.pathSegments[index + 1];
        if (_videoIdRegex.hasMatch(candidate)) {
          return candidate;
        }
      }
    }

    // Live URL: /live/VIDEO_ID
    if (uri.pathSegments.contains('live')) {
      final index = uri.pathSegments.indexOf('live');
      if (index + 1 < uri.pathSegments.length) {
        final candidate = uri.pathSegments[index + 1];
        if (_videoIdRegex.hasMatch(candidate)) {
          return candidate;
        }
      }
    }

    return null;
  }

  /// Normalizes a valid videoId into a canonical clean watch URL
  static String normalizeToWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Returns canonical thumbnail URL for a video ID
  static String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
