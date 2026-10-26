import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';

class DownloadsController extends ChangeNotifier {
  final DownloadRepository _repository;
  StreamSubscription<List<DownloadTask>>? _subscription;

  List<DownloadTask> _tasks = [];
  final bool _isLoading = false;
  String? _errorMessage;

  DownloadsController({required DownloadRepository repository})
    : _repository = repository {
    _init();
  }

  List<DownloadTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _subscription = _repository.watchTasks().listen((tasksList) {
      _tasks = tasksList;
      notifyListeners();
    });
  }

  Future<void> startDownload(String url, {String? preferredName}) async {
    _errorMessage = null;
    try {
      await _repository.startDownload(url: url, preferredName: preferredName);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelTask(String id) async {
    await _repository.cancelTask(id);
  }

  Future<void> retryTask(String id) async {
    await _repository.retryTask(id);
  }

  Future<void> clearFinished() async {
    await _repository.clearFinishedTasks();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
