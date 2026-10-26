import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:downtube/core/theme/app_theme.dart';
import 'package:downtube/domain/entities/media_item.dart';
import 'package:downtube/domain/entities/youtube_video.dart';
import 'package:downtube/domain/repositories/media_library_repository.dart';
import 'package:downtube/domain/repositories/youtube_repository.dart';
import 'package:downtube/data/storage/app_storage.dart';
import 'package:downtube/features/home/home_screen.dart';
import 'package:downtube/features/library/library_controller.dart';

class FakeYouTubeRepository implements YouTubeRepository {
  @override
  Future<YouTubeVideo> getVideoDetails(String videoId) async {
    return YouTubeVideo(
      id: videoId,
      title: 'Test Video',
      authorName: 'Test Channel',
      authorUrl: 'https://youtube.com',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      originalUrl: 'https://youtube.com/watch?v=$videoId',
    );
  }
}

class FakeMediaLibraryRepository implements MediaLibraryRepository {
  final List<MediaItem> _items = [];

  @override
  Future<MediaItem> importFromLocalUri({
    required String uri,
    required String displayName,
    int? sizeBytes,
    String? mimeType,
  }) async {
    final item = MediaItem(
      id: '1',
      displayName: displayName,
      uri: uri,
      dateAdded: DateTime.now(),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<List<MediaItem>> listMedia({
    MediaSortBy sortBy = MediaSortBy.dateAdded,
  }) async {
    return _items;
  }

  @override
  Future<MediaItem?> getMedia(String id) async => null;

  @override
  Future<void> removeLibraryEntry(String id) async {}

  @override
  Future<bool> deletePhysicalFile(String id) async => true;

  @override
  Future<void> verifyAvailability() async {}
}

void main() {
  testWidgets('HomeScreen renders correctly and validates empty input', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = AppStorage(prefs);
    final fakeLibraryRepo = FakeMediaLibraryRepository();
    final fakeYouTubeRepo = FakeYouTubeRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppStorage>.value(value: storage),
          Provider<YouTubeRepository>.value(value: fakeYouTubeRepo),
          Provider<MediaLibraryRepository>.value(value: fakeLibraryRepo),
          ChangeNotifierProvider(
            create: (_) => LibraryController(
              repository: fakeLibraryRepo,
              storage: storage,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: HomeScreen(onNavigateToLibrary: () {}),
        ),
      ),
    );

    // Verify main components are present
    expect(find.byType(RichText), findsWidgets);
    expect(find.text('YouTube Link'), findsOneWidget);
    expect(find.text('Open Video'), findsOneWidget);
    expect(find.text('Import Local Video'), findsOneWidget);

    // Tap "Open Video" without entering any text
    await tester.tap(find.text('Open Video'));
    await tester.pump();

    // Verify inline error message appears
    expect(
      find.text('Please enter or paste a YouTube video link.'),
      findsOneWidget,
    );

    // Enter invalid non-YouTube URL
    await tester.enterText(
      find.byType(TextField),
      'https://invalid-site.com/video',
    );
    await tester.tap(find.text('Open Video'));
    await tester.pump();

    // Verify unsupported URL error message appears
    expect(
      find.text(
        'Unsupported URL. Please enter a valid YouTube link (e.g. youtube.com/watch?v=... or youtu.be/...)',
      ),
      findsOneWidget,
    );
  });
}
