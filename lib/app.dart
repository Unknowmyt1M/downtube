import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/share_intent_handler.dart';
import 'core/utils/youtube_url_parser.dart';
import 'domain/repositories/youtube_repository.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/video_details/video_details_screen.dart';

class DownTubeApp extends StatefulWidget {
  const DownTubeApp({super.key});

  @override
  State<DownTubeApp> createState() => _DownTubeAppState();
}

class _DownTubeAppState extends State<DownTubeApp> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _setupShareIntentListener();
  }

  void _setupShareIntentListener() async {
    ShareIntentHandler.initialize();

    // Check for initial intent that launched the app
    final initialText = await ShareIntentHandler.getInitialSharedText();
    if (initialText != null) {
      _processIncomingShare(initialText);
    }

    // Listen for intents while app is running/backgrounded
    _shareSubscription = ShareIntentHandler.sharedTextStream.listen((text) {
      _processIncomingShare(text);
    });
  }

  void _processIncomingShare(String text) async {
    final videoId = YouTubeUrlParser.extractVideoId(text);
    if (videoId != null && mounted) {
      setState(() => _currentIndex = 0); // Switch to Home tab
      try {
        final youtubeRepo = context.read<YouTubeRepository>();
        final video = await youtubeRepo.getVideoDetails(videoId);
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => VideoDetailsScreen(video: video),
          ),
        );
      } catch (_) {
        // Fallback / gracefully handled in UI
      }
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToLibrary: () => _onTabSelected(1)),
      const LibraryScreen(),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return MaterialApp(
      title: 'DownTube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: _navigatorKey,
      home: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.download_outlined),
              activeIcon: Icon(Icons.download_rounded),
              label: 'Downloads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
