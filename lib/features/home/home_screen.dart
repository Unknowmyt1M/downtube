import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/errors/failures.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/youtube_url_parser.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/youtube_repository.dart';
import '../../data/storage/app_storage.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../video_details/video_details_screen.dart';
import '../library/library_controller.dart';
import '../player/local_player_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToLibrary;

  const HomeScreen({super.key, required this.onNavigateToLibrary});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPastePressed() async {
    final clipboardData = await Clipboard.getData('text/plain');
    final text = clipboardData?.text;
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _urlController.text = text.trim();
        _errorMessage = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty or does not contain text.'),
            backgroundColor: AppColors.cardSurfaceLight,
          ),
        );
      }
    }
  }

  void _clearInput() {
    setState(() {
      _urlController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _handleOpenVideo() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or paste a YouTube video link.';
      });
      return;
    }

    final videoId = YouTubeUrlParser.extractVideoId(input);
    if (videoId == null) {
      setState(() {
        _errorMessage =
            'Unsupported URL. Please enter a valid YouTube link (e.g. youtube.com/watch?v=... or youtu.be/...)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final youtubeRepo = context.read<YouTubeRepository>();
      final storage = context.read<AppStorage>();

      final video = await youtubeRepo.getVideoDetails(videoId);
      await storage.addRecentUrl(video.originalUrl);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoDetailsScreen(video: video),
        ),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'An unexpected error occurred while loading video details.';
      });
    }
  }

  Future<void> _handleImportVideo() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.video);

      if (files.isNotEmpty && mounted) {
        final file = files.first;
        final path = file.path ?? file.xFile.path;
        final libraryController = context.read<LibraryController>();
        final item = await libraryController.importVideo(
          path: path,
          name: file.name,
          size: file.lengthSync(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${item.displayName}" to Library'),
            backgroundColor: AppColors.cardSurfaceLight,
            action: SnackBarAction(
              label: 'View',
              textColor: AppColors.accentHighlight,
              onPressed: widget.onNavigateToLibrary,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryController = context.watch<LibraryController>();
    final recentItems = libraryController.items.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_filled_rounded,
                color: AppColors.primaryAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Down',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Tube',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryAccent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Value Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1065), Color(0xFF191925)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.accentHighlight,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Authorized Media & Player',
                        style: TextStyle(
                          color: AppColors.accentHighlight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Paste YouTube links or organize local video library',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Smooth inline playback, offline library management, and zero clutter.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // URL Input Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'YouTube Link',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'https://youtube.com/watch?v=... or youtu.be/...',
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: AppColors.secondaryText,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_urlController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: AppColors.secondaryText,
                              ),
                              onPressed: _clearInput,
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 20,
                              color: AppColors.primaryAccent,
                            ),
                            tooltip: 'Paste from clipboard',
                            onPressed: _onPastePressed,
                          ),
                        ],
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                    onSubmitted: (_) => _handleOpenVideo(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Open Video',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleOpenVideo,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Import Local Video',
                    icon: Icons.file_upload_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: _handleImportVideo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Local Videos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Local Videos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                if (recentItems.isNotEmpty)
                  TextButton(
                    onPressed: widget.onNavigateToLibrary,
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentItems.isEmpty)
              AppCard(
                color: AppColors.secondaryBackground.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 36,
                        color: AppColors.secondaryText.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No local videos imported yet',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Import from Storage'),
                        onPressed: _handleImportVideo,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(180, 36),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = recentItems[index];
                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              LocalPlayerScreen(mediaItem: item),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.movie_creation_outlined,
                            color: AppColors.primaryAccent,
                            size: 24,
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
                              Text(
                                item.availability == MediaAvailability.available
                                    ? 'Local file • Ready to play'
                                    : 'File missing or moved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      item.availability ==
                                          MediaAvailability.available
                                      ? AppColors.secondaryText
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.primaryAccent,
                          size: 28,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
