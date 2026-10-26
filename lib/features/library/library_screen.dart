import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/media_item.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'library_controller.dart';
import '../player/local_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Future<void> _handleImport() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.video);

      if (files.isNotEmpty && mounted) {
        final file = files.first;
        final path = file.path ?? file.xFile.path;
        final controller = context.read<LibraryController>();
        await controller.importVideo(
          path: path,
          name: file.name,
          size: file.lengthSync(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDetailsModal(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Media Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', item.displayName),
              _buildDetailRow('Size', Formatters.formatBytes(item.sizeBytes)),
              _buildDetailRow(
                'Added On',
                Formatters.formatDate(item.dateAdded),
              ),
              _buildDetailRow('MIME Type', item.mimeType ?? 'video/mp4'),
              _buildDetailRow('File Path', item.uri),
              _buildDetailRow(
                'Status',
                item.availability == MediaAvailability.available
                    ? 'Available'
                    : 'Missing',
                valueColor: item.availability == MediaAvailability.available
                    ? AppColors.success
                    : AppColors.error,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Close',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFile(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Delete File Permanently?'),
        content: Text(
          'This will permanently delete "${item.displayName}" from your device storage. This action cannot be undone.',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
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
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 36),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final controller = context.read<LibraryController>();
              final deleted = await controller.deletePhysicalFile(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      deleted
                          ? 'File deleted from storage and library.'
                          : 'Entry removed from library.',
                    ),
                    backgroundColor: AppColors.cardSurfaceLight,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Import Video',
            onPressed: _handleImport,
          ),
          PopupMenuButton<MediaSortBy>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort By',
            initialValue: controller.sortBy,
            onSelected: (sort) => controller.setSortBy(sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MediaSortBy.dateAdded,
                child: Text('Date Added'),
              ),
              const PopupMenuItem(
                value: MediaSortBy.name,
                child: Text('Name (A-Z)'),
              ),
              const PopupMenuItem(
                value: MediaSortBy.size,
                child: Text('File Size'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.cardSurface,
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Library is Empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Import video files from your device storage to organize and play them offline anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Import Video File',
                        icon: Icons.file_upload_outlined,
                        width: 200,
                        onPressed: _handleImport,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  final isAvailable =
                      item.availability == MediaAvailability.available;

                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      if (isAvailable) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                LocalPlayerScreen(mediaItem: item),
                          ),
                        );
                      } else {
                        _showDetailsModal(context, item);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isAvailable
                                ? Icons.play_arrow_rounded
                                : Icons.broken_image_outlined,
                            color: isAvailable
                                ? AppColors.primaryAccent
                                : AppColors.error,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    Formatters.formatBytes(item.sizeBytes),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isAvailable)
                                    const StatusBadge(
                                      label: 'Missing',
                                      color: AppColors.error,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.secondaryText,
                            size: 20,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case 'play':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LocalPlayerScreen(mediaItem: item),
                                  ),
                                );
                                break;
                              case 'details':
                                _showDetailsModal(context, item);
                                break;
                              case 'remove':
                                controller.removeEntry(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Removed entry from library (file preserved).',
                                    ),
                                    backgroundColor: AppColors.cardSurfaceLight,
                                  ),
                                );
                                break;
                              case 'delete':
                                _confirmDeleteFile(context, item);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (isAvailable)
                              const PopupMenuItem(
                                value: 'play',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Play'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bookmark_remove_outlined,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Remove from Library'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete File Permanently',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
