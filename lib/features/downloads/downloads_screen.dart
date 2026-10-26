import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/media_item.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'downloads_controller.dart';
import '../player/local_player_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  void _showAddDownloadDialog(BuildContext context) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const Text('New Authorized Download'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct video file URL (.mp4, .webm, .mkv from authorized servers):',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/sample.mp4',
                      prefixIcon: Icon(
                        Icons.link_rounded,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Optional file name (e.g. MyVideo.mp4)',
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  minimumSize: const Size(100, 36),
                ),
                onPressed: () async {
                  final url = urlController.text.trim();
                  if (url.isEmpty) {
                    setDialogState(() {
                      dialogError = 'Please enter a URL.';
                    });
                    return;
                  }

                  try {
                    final controller = dialogCtx.read<DownloadsController>();
                    await controller.startDownload(
                      url,
                      preferredName: nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : null,
                    );
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                  } catch (e) {
                    setDialogState(() {
                      dialogError = e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );
                    });
                  }
                },
                child: const Text('Start'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DownloadsController>();
    final tasks = controller.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Direct Download',
            onPressed: () => _showAddDownloadDialog(context),
          ),
          if (tasks.any(
            (t) =>
                t.status == DownloadTaskStatus.completed ||
                t.status == DownloadTaskStatus.failed ||
                t.status == DownloadTaskStatus.cancelled,
          ))
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: 'Clear Finished Tasks',
              onPressed: () => controller.clearFinished(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Policy Transparency Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentHighlight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Downloads are strictly limited to authorized direct media files. YouTube streams cannot be extracted into MP4.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_done_rounded,
                          size: 48,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Downloads',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Download files directly from permitted external servers using direct file URLs (.mp4, .webm).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Download from URL',
                        icon: Icons.add_link_rounded,
                        width: 200,
                        onPressed: () => _showAddDownloadDialog(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskCard(context, task, controller);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    DownloadTask task,
    DownloadsController controller,
  ) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (task.status) {
      case DownloadTaskStatus.queued:
        statusColor = AppColors.warning;
        statusLabel = 'Queued';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case DownloadTaskStatus.downloading:
        statusColor = AppColors.primaryAccent;
        statusLabel = task.progress != null
            ? '${(task.progress! * 100).toInt()}%'
            : 'Downloading';
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadTaskStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case DownloadTaskStatus.failed:
        statusColor = AppColors.error;
        statusLabel = 'Failed';
        statusIcon = Icons.error_outline_rounded;
        break;
      case DownloadTaskStatus.cancelled:
        statusColor = AppColors.secondaryText;
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              StatusBadge(
                label: statusLabel,
                color: statusColor,
                icon: statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.sourceReference,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),

          // Progress indicator for downloading tasks
          if (task.status == DownloadTaskStatus.downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: AppColors.secondaryBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccent,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.totalBytes != null
                      ? '${Formatters.formatBytes(task.bytesReceived)} / ${Formatters.formatBytes(task.totalBytes)}'
                      : Formatters.formatBytes(task.bytesReceived),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.cancelTask(task.id),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          if (task.status == DownloadTaskStatus.failed &&
              task.errorCode != null) ...[
            Text(
              task.errorCode!,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
            const SizedBox(height: 6),
          ],

          // Completed or Failed action buttons
          if (task.status == DownloadTaskStatus.completed &&
              task.outputUri != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Play Video'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () {
                  final mediaItem = MediaItem(
                    id: task.id,
                    displayName: task.displayName,
                    uri: task.outputUri!,
                    sizeBytes: task.totalBytes ?? task.bytesReceived,
                    dateAdded: task.updatedAt,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          LocalPlayerScreen(mediaItem: mediaItem),
                    ),
                  );
                },
              ),
            ),
          ],

          if (task.status == DownloadTaskStatus.failed ||
              task.status == DownloadTaskStatus.cancelled) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => controller.retryTask(task.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
