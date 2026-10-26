import 'dart:async';
import 'package:path/path.dart' as p;
import '../../core/errors/failures.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/media_library_repository.dart';
import '../services/direct_download_provider.dart';
import '../storage/app_storage.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final AppStorage _storage;
  final MediaLibraryRepository _mediaLibraryRepository;
  final List<DownloadProvider> _providers;
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController<List<DownloadTask>>.broadcast();

  DownloadRepositoryImpl({
    required AppStorage storage,
    required MediaLibraryRepository mediaLibraryRepository,
    List<DownloadProvider>? providers,
  }) : _storage = storage,
       _mediaLibraryRepository = mediaLibraryRepository,
       _providers = providers ?? [DirectFileDownloadProvider()];

  @override
  List<DownloadProvider> get providers => List.unmodifiable(_providers);

  @override
  bool isSupported(String url) {
    return _providers.any((p) => p.supports(url));
  }

  DownloadProvider? _getProviderForUrl(String url) {
    try {
      return _providers.firstWhere((p) => p.supports(url));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DownloadTask> startDownload({
    required String url,
    String? preferredName,
  }) async {
    final provider = _getProviderForUrl(url);
    if (provider == null) {
      throw const UnsupportedSourceFailure(
        'Direct download extraction is not supported for this source. '
        'YouTube videos must be played via the integrated player in accordance with official platform terms.',
      );
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    var name = preferredName;
    if (name == null || name.trim().isEmpty) {
      try {
        final uri = Uri.parse(url);
        name = p.basename(uri.path);
        if (name.isEmpty) name = 'video_$id.mp4';
      } catch (_) {
        name = 'video_$id.mp4';
      }
    }

    var task = DownloadTask(
      id: id,
      sourceType: provider.id,
      sourceReference: url,
      displayName: name,
      status: DownloadTaskStatus.queued,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _updateTask(task);

    // Launch download asynchronously
    _executeDownload(provider, task);

    return task;
  }

  void _executeDownload(
    DownloadProvider provider,
    DownloadTask initialTask,
  ) async {
    var task = initialTask.copyWith(
      status: DownloadTaskStatus.downloading,
      updatedAt: DateTime.now(),
    );
    await _updateTask(task);

    try {
      final outputPath = await provider.download(
        task: task,
        onProgress: (received, total) {
          task = task.copyWith(
            bytesReceived: received,
            totalBytes: total > 0 ? total : null,
            updatedAt: DateTime.now(),
          );
          _updateTask(task);
        },
      );

      // Verified completed
      task = task.copyWith(
        status: DownloadTaskStatus.completed,
        outputUri: outputPath,
        updatedAt: DateTime.now(),
      );
      await _updateTask(task);

      // Register file into local Media Library
      await _mediaLibraryRepository.importFromLocalUri(
        uri: outputPath,
        displayName: task.displayName,
        sizeBytes: task.totalBytes ?? task.bytesReceived,
      );
    } catch (e) {
      final isCancelled = e.toString().contains('cancelled');
      task = task.copyWith(
        status: isCancelled
            ? DownloadTaskStatus.cancelled
            : DownloadTaskStatus.failed,
        errorCode: e.toString(),
        updatedAt: DateTime.now(),
      );
      await _updateTask(task);
    }
  }

  Future<void> _updateTask(DownloadTask task) async {
    final tasks = _storage.getDownloadTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    await _storage.saveDownloadTasks(tasks);
    _tasksController.add(tasks);
  }

  @override
  Future<List<DownloadTask>> getTasks() async {
    return _storage.getDownloadTasks();
  }

  @override
  Stream<List<DownloadTask>> watchTasks() async* {
    yield _storage.getDownloadTasks();
    yield* _tasksController.stream;
  }

  @override
  Future<void> cancelTask(String taskId) async {
    final tasks = _storage.getDownloadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = tasks[index];
    final provider = _providers.firstWhere(
      (p) => p.id == task.sourceType,
      orElse: () => _providers.first,
    );
    provider.cancel(taskId);

    final updated = task.copyWith(
      status: DownloadTaskStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _updateTask(updated);
  }

  @override
  Future<void> retryTask(String taskId) async {
    final tasks = _storage.getDownloadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = tasks[index];
    final provider = _getProviderForUrl(task.sourceReference);
    if (provider == null) {
      throw const UnsupportedSourceFailure('Source is no longer supported.');
    }

    final retrying = task.copyWith(
      status: DownloadTaskStatus.queued,
      errorCode: null,
      bytesReceived: 0,
      updatedAt: DateTime.now(),
    );
    await _updateTask(retrying);
    _executeDownload(provider, retrying);
  }

  @override
  Future<void> clearFinishedTasks() async {
    final tasks = _storage.getDownloadTasks();
    tasks.removeWhere(
      (t) =>
          t.status == DownloadTaskStatus.completed ||
          t.status == DownloadTaskStatus.failed ||
          t.status == DownloadTaskStatus.cancelled,
    );
    await _storage.saveDownloadTasks(tasks);
    _tasksController.add(tasks);
  }
}
