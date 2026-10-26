import 'dart:async';
import 'package:flutter/services.dart';

class ShareIntentHandler {
  static const MethodChannel _channel = MethodChannel(
    'com.downtube.downtube/share_intent',
  );

  static final StreamController<String> _sharedTextController =
      StreamController<String>.broadcast();

  static Stream<String> get sharedTextStream => _sharedTextController.stream;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments;
        if (text is String && text.trim().isNotEmpty) {
          _sharedTextController.add(text.trim());
        }
      }
    });
  }

  static Future<String?> getInitialSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
    } catch (_) {
      // Gracefully ignore channel exceptions on unsupported platforms (e.g. tests)
    }
    return null;
  }
}
