import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/download_repository_impl.dart';
import 'data/repositories/media_library_repository_impl.dart';
import 'data/repositories/youtube_repository_impl.dart';
import 'data/storage/app_storage.dart';
import 'domain/repositories/download_repository.dart';
import 'domain/repositories/media_library_repository.dart';
import 'domain/repositories/youtube_repository.dart';
import 'features/downloads/downloads_controller.dart';
import 'features/library/library_controller.dart';
import 'features/settings/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final storage = await AppStorage.init();

  // Repositories
  final youtubeRepository = YouTubeRepositoryImpl();
  final mediaLibraryRepository = MediaLibraryRepositoryImpl(storage);
  final downloadRepository = DownloadRepositoryImpl(
    storage: storage,
    mediaLibraryRepository: mediaLibraryRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        // Storage & Repositories
        Provider<AppStorage>.value(value: storage),
        Provider<YouTubeRepository>.value(value: youtubeRepository),
        Provider<MediaLibraryRepository>.value(value: mediaLibraryRepository),
        Provider<DownloadRepository>.value(value: downloadRepository),

        // Controllers
        ChangeNotifierProvider(
          create: (_) => LibraryController(
            repository: mediaLibraryRepository,
            storage: storage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadsController(repository: downloadRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(storage: storage),
        ),
      ],
      child: const DownTubeApp(),
    ),
  );
}
