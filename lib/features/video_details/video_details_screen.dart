import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/youtube_video.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../downloads/downloads_controller.dart';
import '../player/youtube_player_screen.dart';

class VideoDetailsScreen extends StatelessWidget {
  final YouTubeVideo video;

  const VideoDetailsScreen({super.key, required this.video});

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: video.originalUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video link copied to clipboard'),
        backgroundColor: AppColors.cardSurfaceLight,
      ),
    );
  }

  void _openInYouTubeApp(BuildContext context) async {
    final uri = Uri.parse(video.originalUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open external YouTube app.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch external browser or app.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDownloadQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: AppColors.primaryAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'yt-dlp + FFmpeg Download',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildQualityOption(
                context: context,
                sheetContext: sheetContext,
                title: 'Best Video (1080p / 4K)',
                subtitle: 'Merged audio + video stream via local FFmpeg',
                icon: Icons.high_quality_rounded,
              ),
              const SizedBox(height: 8),
              _buildQualityOption(
                context: context,
                sheetContext: sheetContext,
                title: 'Standard (720p MP4)',
                subtitle: 'Fast single-stream download',
                icon: Icons.video_file_rounded,
              ),
              const SizedBox(height: 8),
              _buildQualityOption(
                context: context,
                sheetContext: sheetContext,
                title: 'Audio Only (M4A)',
                subtitle: 'High bitrate audio track',
                icon: Icons.audiotrack_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption({
    required BuildContext context,
    required BuildContext sheetContext,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        Navigator.of(sheetContext).pop();
        try {
          final downloadsController = context.read<DownloadsController>();
          await downloadsController.startDownload(
            video.originalUrl,
            preferredName: '${video.title}.mp4',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'yt-dlp download started! Track progress in Downloads tab.',
                ),
                backgroundColor: AppColors.cardSurfaceLight,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download failed to start: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentHighlight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy URL',
            onPressed: () => _copyUrl(context),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            tooltip: 'Open in YouTube App',
            onPressed: () => _openInYouTubeApp(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 16:9 Aspect Ratio Thumbnail Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.secondaryBackground,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.video_camera_back_outlined,
                          size: 48,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.secondaryBackground,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  YouTubePlayerScreen(video: video),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Title & Channel Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const StatusBadge(
                        label: 'YouTube Online',
                        color: AppColors.primaryAccent,
                        icon: Icons.public_rounded,
                      ),
                      const Spacer(),
                      Text(
                        'ID: ${video.id}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.secondaryBackground,
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppColors.accentHighlight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.authorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const Text(
                              'Channel / Creator',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Actions & Downloader',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Download Video (yt-dlp + FFmpeg)',
                    icon: Icons.download_rounded,
                    onPressed: () => _showDownloadQualitySheet(context),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Play In-App (Integrated Player)',
                    icon: Icons.play_circle_filled_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              YouTubePlayerScreen(video: video),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Open in YouTube App',
                    icon: Icons.open_in_new_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => _openInYouTubeApp(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
