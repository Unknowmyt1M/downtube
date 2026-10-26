# DownTube — Technical Specification

## 1. Architecture Overview
DownTube follows clean, modular, feature-first architecture in Flutter:

```
lib/
├── core/
│   ├── errors/         # Typed domain failures (InvalidUrlFailure, etc.)
│   ├── routing/        # App router and screen navigation
│   ├── theme/          # AppTheme, Dark colors, typography, spacing
│   └── utils/          # URL parser, formatters, share channel
├── domain/
│   ├── entities/       # YouTubeVideo, MediaItem, DownloadTask
│   └── repositories/   # Abstract repository contracts & interfaces
├── data/
│   ├── models/         # JSON / persistent serialization models
│   ├── repositories/   # Concrete repository implementations
│   ├── services/       # YouTube oEmbed / metadata API, Dio downloader
│   └── storage/        # SharedPreferences persistence layer
├── features/
│   ├── home/           # URL input, clipboard paste, quick action cards
│   ├── video_details/  # Video preview, metadata view, action router
│   ├── player/         # YouTube IFrame player + Local video player
│   ├── library/        # Local media manager, SAF importer, sorting
│   ├── downloads/      # Authorized download manager & tasks queue
│   └── settings/       # Theme, sort prefs, privacy disclosures
└── shared/
    └── widgets/        # App buttons, cards, badges, text inputs
```

## 2. Key Modules & Contracts

### 2.1 YouTubeRepository
- `getVideoDetails(String videoId)`: Retrieves legitimate title, author, thumbnail via YouTube oEmbed protocol (official, keyless, zero-cost, no quota exhaustion).
- Guarantees: Never fabricates non-existent MP4 stream URLs.

### 2.2 MediaLibraryRepository
- `importFromUri(String uri, String name, int size, String mimeType)`: Registers picked file with persistent storage.
- `listMedia({SortBy sortBy})`: Loads all local files, verifies file existence, sorts by Date/Name/Size.
- `removeEntry(String id)`: Removes metadata without destructive file deletion.
- `deleteFile(String id)`: Explicit confirmation flow to delete file physically.

### 2.3 DownloadProvider & DownloadRepository
- `DownloadProvider`: Interface for authorized sources (`supports(url)`, `startDownload(request)`).
- Rejects unauthorized / arbitrary YouTube URLs with honest explanation.
- Progress tracking via Dio stream chunks with verified output validation before marking completed.

## 3. Platform Integration
- Android Share Intent: Implemented via Kotlin MethodChannel `com.downtube.downtube/share_intent` handling `ACTION_SEND` text/plain.
- Storage Access Framework: Uses `file_picker` to obtain scoped storage URIs/paths without invasive broad storage permissions.
