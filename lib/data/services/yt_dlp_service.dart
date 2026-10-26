import 'dart:async';
import 'package:flutter/services.dart';

class YtDlpProgressEvent {
  final String processId;
  final double progress;
  final int? eta;
  final String? log;

  const YtDlpProgressEvent({
    required this.processId,
    required this.progress,
    this.eta,
    this.log,
  });
}

class YtDlpService {
  static const MethodChannel _channel = MethodChannel(
    'com.downtube.downtube/ytdlp',
  );

  static final StreamController<YtDlpProgressEvent> _progressController =
      StreamController<YtDlpProgressEvent>.broadcast();

  static Stream<YtDlpProgressEvent> get progressStream =>
      _progressController.stream;

  static bool _handlerInitialized = false;

  static void initHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        final map = call.arguments;
        if (map is Map) {
          final processId = map['processId']?.toString() ?? '';
          final progress = (map['progress'] as num?)?.toDouble() ?? 0.0;
          final eta = (map['eta'] as num?)?.toInt();
          final log = map['log']?.toString();

          _progressController.add(
            YtDlpProgressEvent(
              processId: processId,
              progress: progress,
              eta: eta,
              log: log,
            ),
          );
        }
      }
    });
  }

  static Future<bool> initEngine() async {
    initHandler();
    try {
      final res = await _channel.invokeMethod<bool>('init');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> download({
    required String url,
    required String processId,
    required String outputDir,
    String format = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
  }) async {
    initHandler();
    try {
      final res = await _channel.invokeMethod<Map>('download', {
        'url': url,
        'processId': processId,
        'outputDir': outputDir,
        'format': format,
      });
      return Map<String, dynamic>.from(res ?? {});
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'yt-dlp execution failed');
    }
  }

  static Future<void> cancel(String processId) async {
    try {
      await _channel.invokeMethod('cancel', {'processId': processId});
    } catch (_) {}
  }
}
