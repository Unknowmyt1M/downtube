import '../entities/download_task.dart';

abstract class DownloadProvider {
  /// Provider identifier (e.g. 'direct_http')
  String get id;

  /// Human-readable provider label
  String get label;

  /// Returns whether this provider can handle and is authorized to download from this source
  bool supports(String url);

  /// Validates the source URL before attempting download
  Future<bool> validate(String url);

  /// Performs the download operation
  Future<String> download({
    required DownloadTask task,
    required void Function(int received, int total) onProgress,
  });

  /// Cancels an active download
  void cancel(String taskId);
}

abstract class DownloadRepository {
  /// List of registered providers
  List<DownloadProvider> get providers;

  /// Checks if any registered provider supports the source
  bool isSupported(String url);

  /// Creates a download task if an authorized provider supports the URL.
  /// Throws [UnsupportedSourceFailure] if no provider supports it (e.g. YouTube stream extraction).
  Future<DownloadTask> startDownload({
    required String url,
    String? preferredName,
  });

  /// Gets all tracked tasks
  Future<List<DownloadTask>> getTasks();

  /// Watches stream of task updates
  Stream<List<DownloadTask>> watchTasks();

  /// Cancels a running task
  Future<void> cancelTask(String taskId);

  /// Retries a failed or cancelled task
  Future<void> retryTask(String taskId);

  /// Clears completed/failed tasks
  Future<void> clearFinishedTasks();
}
