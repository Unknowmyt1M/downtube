import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import 'yt_dlp_service.dart';

class YtDlpDownloadProvider implements DownloadProvider {
  StreamSubscription<YtDlpProgressEvent>? _sub;

  @override
  String get id => 'yt_dlp_engine';

  @override
  String get label => 'yt-dlp + FFmpeg Engine';

  @override
  bool supports(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> validate(String url) async {
    return supports(url);
  }

  @override
  Future<String> download({
    required DownloadTask task,
    required void Function(int received, int total) onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(appDir.path, 'downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final completer = Completer<String>();

    _sub = YtDlpService.progressStream.listen((event) {
      if (event.processId == task.id) {
        // event.progress is 0.0 to 100.0
        final progressFraction = (event.progress / 100.0).clamp(0.0, 1.0);
        final simulatedTotal = 1000;
        final simulatedReceived = (progressFraction * simulatedTotal).round();
        onProgress(simulatedReceived, simulatedTotal);
      }
    });

    try {
      final result = await YtDlpService.download(
        url: task.sourceReference,
        processId: task.id,
        outputDir: downloadsDir.path,
        format: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
      );

      // Locate downloaded file in directory
      final files = downloadsDir.listSync();
      File? latestFile;
      for (final f in files) {
        if (f is File &&
            !f.path.endsWith('.part') &&
            !f.path.endsWith('.ytdl')) {
          if (latestFile == null ||
              f.lastModifiedSync().isAfter(latestFile.lastModifiedSync())) {
            latestFile = f;
          }
        }
      }

      if (latestFile != null && await latestFile.exists()) {
        completer.complete(latestFile.path);
      } else {
        final outLog = result['output']?.toString() ?? 'No output';
        completer.completeError(
          StorageFailure('yt-dlp output missing: $outLog'),
        );
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(StorageFailure(e.toString()));
      }
    } finally {
      await _sub?.cancel();
    }

    return completer.future;
  }

  @override
  void cancel(String taskId) {
    YtDlpService.cancel(taskId);
  }
}
