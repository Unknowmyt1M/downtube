# DownTube — Test Plan

## 1. Unit Tests
- **YouTube URL Parser**:
  - Standard watch URLs: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
  - Shortened URLs: `https://youtu.be/dQw4w9WgXcQ`
  - Shorts URLs: `https://www.youtube.com/shorts/dQw4w9WgXcQ`
  - Embedded URLs: `https://www.youtube.com/embed/dQw4w9WgXcQ`
  - Malformed inputs, unrelated domains, missing video IDs.
- **Library Model & Sorting**:
  - Sort by date added, name, size.
  - MediaItem serializing & deserializing.
- **Download Provider Verification**:
  - Supported direct authorized sources vs unsupported YouTube URLs.
  - Task state transitions: Queued -> Downloading -> Completed / Failed / Cancelled.

## 2. Widget Tests
- **Home Screen**:
  - Input URL field, Paste button tap, validation error messages.
  - Navigation triggers to Details.
- **Library Screen**:
  - Empty state rendering with "Import Video" action.
  - Populated library cards with duration, size, and overflow options.
- **Downloads Screen**:
  - Empty state displaying provider capability explanation.
  - Task progress indicator and cancellation button.

## 3. CI/CD Automated Verification
- GitHub Actions workflow running `flutter analyze`, `flutter test`, and building a debug APK artifact.
