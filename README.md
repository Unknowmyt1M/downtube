# DownTube 🎬

> A premium-feeling Android video utility focused on YouTube playback, authorized video downloads, and local media management.

[![CI & Build](https://github.com/downtube/downtube/actions/workflows/android.yml/badge.svg)](.github/workflows/android.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

---

## ✨ Features

- 💜 **Premium Dark Theme**: Sleek violet & purple accents (`#8B5CF6`, `#A78BFA`) over deep dark surfaces (`#0B0B10`, `#191925`).
- 🔗 **YouTube Link Support**: Instant URL parsing and validation for standard watch URLs, shortened `youtu.be` links, YouTube Shorts, embed links, and direct video IDs.
- 📺 **Compliant YouTube Playback**: In-app streaming via the official YouTube IFrame Player API, strictly complying with YouTube Terms of Service, with a one-tap external YouTube app fallback.
- 📱 **Android Share Target**: Accepts shared links directly from the YouTube app or any web browser via Android's native share intent (`ACTION_SEND`).
- 📁 **Offline Local Library**: Import video files using Android's system Storage Access Framework (`file_picker`). Sort by Date Added, Name, or Size.
- 🎞️ **Integrated Local Video Player**: Smooth playback for imported local media (`video_player`) with scrubbing, 10s skip controls, and time elapsed/duration display.
- 📥 **Authorized Direct Downloader**: Transparent, honest downloading for permitted direct media files (`.mp4`, `.webm`, `.mkv`), rejecting arbitrary YouTube stream extraction to maintain policy compliance.
- 🔒 **Privacy-First**: Zero tracking SDKs, zero telemetry, no accounts or cloud databases required.

---

## 🏗️ Architecture

DownTube uses a modular, feature-first clean architecture:

```
lib/
├── app.dart                        # Main application shell & tab routing
├── main.dart                       # Entry point, dependency injection (MultiProvider)
├── core/
│   ├── errors/                     # Typed domain failures (InvalidUrlFailure, etc.)
│   ├── routing/                    # Navigation helpers
│   ├── theme/                      # AppColors, AppTheme (Material 3 Dark)
│   └── utils/                      # YouTubeUrlParser, Formatters, ShareIntentHandler
├── domain/
│   ├── entities/                   # YouTubeVideo, MediaItem, DownloadTask
│   └── repositories/               # Contracts (YouTubeRepository, MediaLibraryRepository, DownloadRepository)
├── data/
│   ├── models/                     # MediaItemModel, DownloadTaskModel
│   ├── repositories/               # Implementations with storage integration
│   ├── services/                   # YouTube oEmbed Service, DirectFileDownloadProvider
│   └── storage/                    # AppStorage (SharedPreferences wrapper)
├── features/
│   ├── home/                       # URL input card, paste action, recent local videos
│   ├── video_details/              # 16:9 thumbnail preview, creator info, actions
│   ├── player/                     # YouTubePlayerScreen & LocalPlayerScreen
│   ├── library/                    # Local media list, details modal, sorting, deletion
│   ├── downloads/                  # Authorized download tasks queue & progress
│   └── settings/                   # Appearance, library sort pref, history, licenses
└── shared/
    └── widgets/                    # AppButton, AppCard, StatusBadge
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ / 3.44+)
- Android SDK (minSdk 24, compileSdk 34+)
- Java JDK 17

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/downtube/downtube.git
   cd downtube
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code analysis & tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch on Android device or emulator**:
   ```bash
   flutter run
   ```

5. **Build Release / Debug APK**:
   ```bash
   flutter build apk --debug
   # or
   flutter build apk --release
   ```

---

## 🧪 Automated Testing

Unit and widget tests cover core business logic and acceptance criteria:

- `test/unit/youtube_url_parser_test.dart`: Validates standard, shortened, shorts, embed, and live links, extra query parameters, and invalid hosts.
- `test/unit/media_library_test.dart`: Tests JSON serialization, availability states, and sorting by name/size/date.
- `test/unit/download_provider_test.dart`: Verifies rejection of YouTube URLs, acceptance of direct files, and task progress computation.
- `test/widget/home_screen_test.dart`: Tests home UI components, empty input validation, and invalid URL feedback.

Run tests:
```bash
flutter test
```

---

## 📋 Acceptance Criteria Checklist

- [x] **FR-01**: YouTube URL parsing and normalization across all URL formats.
- [x] **FR-02**: Android share intent handling for incoming links via Kotlin `MainActivity`.
- [x] **FR-03**: Zero-quota official YouTube oEmbed metadata retrieval + IFrame Player integration.
- [x] **FR-04**: Storage Access Framework local video import, persistent library, safe deletion.
- [x] **FR-05**: Authorized download manager with progress tracking & honest policy explanation.
- [x] **FR-06**: SharedPreferences persistence for preferences, tasks, and media items.
- [x] **FR-07**: Polished dark UI with purple accents, loading, empty, and error states.
- [x] **FR-08**: Controller disposal, zero memory leaks, smooth navigation.
- [x] **CI/CD**: GitHub Actions workflow in `.github/workflows/android.yml`.
