# DownTube — Product Requirements Document (PRD)

Document status: Initial implementation specification  
Product: DownTube  
Platform: Android  
Framework: Flutter + Dart  
Design direction: Premium dark UI, purple accents, smooth animations  
Release target: Functional, testable MVP  
Budget: ₹0 for initial development, subject to external service limits  

---

## 1. Executive summary

DownTube is a premium-feeling Android video utility focused on YouTube playback, authorized video downloads, and local media management.

The app should provide a cohesive experience for opening YouTube links, viewing supported video information, playing videos through an appropriate YouTube player integration, importing authorized media files, and managing local videos.

Downloading must be implemented only through explicitly supported and authorized sources. The app must not assume that a YouTube URL provides a downloadable media file.

### Product principles

1. **Honest capabilities**: Never claim a download succeeded unless a file was actually saved and verified.
2. **Offline-friendly library**: Imported local files should remain accessible without internet.
3. **Privacy-first**: No account, analytics service, or backend is required for the initial MVP.
4. **Lightweight architecture**: Modular code, limited dependencies, and efficient memory use.
5. **Testable delivery**: Every major feature has acceptance criteria and automated tests.
6. **Premium UX**: Consistent spacing, polished dark surfaces, responsive animations, and clear feedback.

---

## 2. Problem statement

Users need a convenient place to open YouTube links and organize video files they are authorized to keep. Existing workflows may separate video playback, file importing, and local media management across different applications.

DownTube aims to bring these permitted workflows into one focused Android app.

**Evidence gap**: This problem statement is a product hypothesis. User interviews, competitor testing, and demand validation have not yet been conducted. The MVP should be used to validate usability before adding complex functionality.

---

## 3. Goals and non-goals

### User goals

- Open a YouTube link quickly.
- See useful video information before playback.
- Import video files from device storage.
- Play and organize imported videos.
- Understand download progress and errors.
- Use the local library without an internet connection.

### Product goals

- Deliver a reliable Android MVP without a paid backend.
- Keep business logic separate from Flutter widgets.
- Support automated testing and repeatable APK builds.
- Make additional authorized download providers possible without redesigning the app.

### Non-goals for MVP

- Arbitrary YouTube-to-MP4 extraction.
- Circumventing DRM, access restrictions, or platform controls.
- Background scraping services or proxy infrastructure.
- User accounts, subscriptions, cloud synchronization, or social features.
- Desktop, iOS, or web releases.
- Guaranteed support for every video URL or external media host.
- A public Play Store release before policy, licensing, and privacy review.

---

## 4. Target users and use cases

- **Primary user**: An Android user who watches YouTube videos and wants a simple, well-designed local video library.
- **Secondary user**: A creator or user who has legitimate access to downloadable video files and wants to manage them locally.

### Main use cases

1. Paste a YouTube URL and open its video.
2. Share a YouTube link from another app into DownTube.
3. Import a video using Android's system file picker.
4. Play an imported video offline.
5. Inspect, sort, and remove library entries.
6. Download a file from a configured, authorized source.
7. Recover gracefully from unsupported URLs, network errors, and storage failures.

---

## 5. Scope and priorities

### P0 — Required for MVP

- Premium dark theme and navigation.
- Home screen with URL input and clipboard-paste action.
- YouTube URL parsing and validation.
- Supported YouTube metadata/thumbnail retrieval, where available.
- Appropriate YouTube player integration.
- Android share intent for supported YouTube URLs.
- Local video import using the Storage Access Framework.
- Local video playback.
- Library list, details, sorting, and removal.
- Persistent app preferences and library metadata.
- Loading, empty, success, and error states.
- Unit and widget tests.
- GitHub Actions workflow for automated tests and APK builds.

### P1 — After MVP validation

- Authorized direct-file download manager.
- Progress, cancellation, retry, and background handling where supported.
- Notifications and download queue.
- Optional SQLite migration if library metadata grows.
- Additional playback controls and accessibility refinements.

### P2 — Future evaluation

- Additional authorized source providers.
- Advanced filtering and playlists.
- Optional backup/export of library metadata.
- Additional themes and customization.

---

## 6. Screen-by-screen UX specification

### 6.1 Home screen
- App bar with DownTube wordmark and settings icon.
- Prominent URL input card with paste button and clear-input action.
- Primary “Open video” button.
- Secondary “Import video” action.
- Recent local videos section.
- Bottom navigation: Home, Library, Downloads, Settings.

### 6.2 Video Details screen
- Thumbnail with a 16:9 aspect ratio.
- Video title and channel information, when available.
- Duration or other metadata only when reliably supplied.
- Primary “Play on YouTube” or embedded-player action.
- Authorized download action only if a configured provider explicitly supports it.
- Overflow menu for copying the URL or opening externally.

### 6.3 Player screen
- YouTube playback: Approved YouTube playback integration consistent with applicable terms. Fallback to open in external YouTube app.
- Local playback: Play supported local video formats, play/pause, seek, elapsed time, duration, full-screen. Safe controller disposal.

### 6.4 Library screen
- Grid/list view with thumbnails, file name, duration, and file size.
- Sort by name, date added, or size.
- Empty-state import button.
- Item actions: Play, View Details, Remove from Library.

### 6.5 Downloads screen
- Clear state for configured authorized providers.
- Display queued, downloading, completed, failed, and cancelled states.
- Rejection of unsupported sources (such as direct YouTube stream extraction) with honest feedback.

### 6.6 Settings screen
- Theme: dark by default.
- Dynamic accent preference.
- Library sorting preference.
- Privacy information & disclosures.
- App version & licenses.
- Clear history action.

---

## 7. Design system
- Primary background: `#0B0B10`
- Secondary background: `#12121B`
- Card surface: `#191925`
- Primary accent: `#8B5CF6`
- Accent highlight: `#A78BFA`
- Primary text: `#F5F3FF`
- Secondary text: `#A5A3B5`
- Error: `#F87171`
- Success: `#4ADE80`
