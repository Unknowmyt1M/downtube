import '../../domain/entities/download_task.dart';

class DownloadTaskModel {
  static Map<String, dynamic> toJson(DownloadTask task) {
    return {
      'id': task.id,
      'sourceType': task.sourceType,
      'sourceReference': task.sourceReference,
      'displayName': task.displayName,
      'status': task.status.name,
      'bytesReceived': task.bytesReceived,
      'totalBytes': task.totalBytes,
      'outputUri': task.outputUri,
      'errorCode': task.errorCode,
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
    };
  }

  static DownloadTask fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'queued';
    final status = DownloadTaskStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => DownloadTaskStatus.queued,
    );

    return DownloadTask(
      id: json['id'] as String,
      sourceType: json['sourceType'] as String? ?? 'direct',
      sourceReference: json['sourceReference'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Download',
      status: status,
      bytesReceived: json['bytesReceived'] as int?,
      totalBytes: json['totalBytes'] as int?,
      outputUri: json['outputUri'] as String?,
      errorCode: json['errorCode'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
