abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class InvalidUrlFailure extends AppFailure {
  const InvalidUrlFailure([
    super.message =
        'The provided URL is not a recognized or supported YouTube link.',
  ]);
}

class UnsupportedSourceFailure extends AppFailure {
  const UnsupportedSourceFailure([
    super.message =
        'Direct extraction from this source is not supported or permitted.',
  ]);
}

class NetworkUnavailableFailure extends AppFailure {
  const NetworkUnavailableFailure([
    super.message =
        'Network connection is unavailable. Please check your internet.',
  ]);
}

class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure([
    super.message = 'Storage access permission was denied.',
  ]);
}

class QuotaExceededFailure extends AppFailure {
  const QuotaExceededFailure([
    super.message = 'Service quota limit reached. Please try again later.',
  ]);
}

class PlaybackUnavailableFailure extends AppFailure {
  const PlaybackUnavailableFailure([
    super.message =
        'Video playback is restricted or unavailable for this media.',
  ]);
}

class StorageFailure extends AppFailure {
  const StorageFailure([
    super.message = 'Failed to read or write local storage.',
  ]);
}
