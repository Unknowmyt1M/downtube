enum DownloadTaskStatus { queued, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String sourceType;
  final String sourceReference;
  final String displayName;
  final DownloadTaskStatus status;
  final int? bytesReceived;
  final int? totalBytes;
  final String? outputUri;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DownloadTask({
    required this.id,
    required this.sourceType,
    required this.sourceReference,
    required this.displayName,
    this.status = DownloadTaskStatus.queued,
    this.bytesReceived,
    this.totalBytes,
    this.outputUri,
    this.errorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  double? get progress {
    if (totalBytes == null || totalBytes! <= 0 || bytesReceived == null) {
      return null;
    }
    return (bytesReceived! / totalBytes!).clamp(0.0, 1.0);
  }

  DownloadTask copyWith({
    String? id,
    String? sourceType,
    String? sourceReference,
    String? displayName,
    DownloadTaskStatus? status,
    int? bytesReceived,
    int? totalBytes,
    String? outputUri,
    String? errorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceReference: sourceReference ?? this.sourceReference,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      outputUri: outputUri ?? this.outputUri,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
