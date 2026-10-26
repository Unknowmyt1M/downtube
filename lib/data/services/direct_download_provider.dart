import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/youtube_url_parser.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';

class DirectFileDownloadProvider implements DownloadProvider {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  DirectFileDownloadProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  String get id => 'authorized_direct_file';

  @override
  String get label => 'Authorized Direct File Provider';

  @override
  bool supports(String url) {
    // Explicitly reject any YouTube URL (official terms & PRD non-goals)
    if (YouTubeUrlParser.extractVideoId(url) != null) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      final pathLower = uri.path.toLowerCase();
      // Supports direct video files from authorized servers
      return pathLower.endsWith('.mp4') ||
          pathLower.endsWith('.mkv') ||
          pathLower.endsWith('.webm') ||
          pathLower.endsWith('.mov') ||
          pathLower.endsWith('.m4v');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> validate(String url) async {
    if (!supports(url)) return false;
    try {
      final response = await _dio.head(
        url,
        options: Options(
          headers: {'User-Agent': 'DownTube/1.0 (Android)'},
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> download({
    required DownloadTask task,
    required void Function(int received, int total) onProgress,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(appDir.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Sanitize filename
      var fileName = task.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      if (!fileName.contains('.')) {
        fileName = '$fileName.mp4';
      }

      final outputPath = p.join(downloadsDir.path, '${task.id}_$fileName');
      final tempPath = '$outputPath.tmp';

      final response = await _dio.download(
        task.sourceReference,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final tempFile = File(tempPath);
        if (await tempFile.exists() && await tempFile.length() > 0) {
          // Rename temp to verified output file
          final finalFile = await tempFile.rename(outputPath);
          return finalFile.path;
        } else {
          throw const StorageFailure('Downloaded file is empty or missing.');
        }
      } else {
        throw StorageFailure(
          'Download failed with server status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const StorageFailure('Download was cancelled.');
      }
      throw NetworkUnavailableFailure(
        e.message ?? 'Network failure during download.',
      );
    } finally {
      _cancelTokens.remove(task.id);
    }
  }

  @override
  void cancel(String taskId) {
    final token = _cancelTokens[taskId];
    if (token != null && !token.isCancelled) {
      token.cancel('User requested cancellation');
      _cancelTokens.remove(taskId);
    }
  }
}
