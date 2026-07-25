# SL Study Assistant — Complete Flutter Project

Offline-first Android study app for Sri Lankan students (O/L & A/L).

---

## COMPLETE FILE LIST

```
sl_study_assistant/
├── pubspec.yaml
├── README.md
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── app/
│       ├── build.gradle
│       ├── proguard-rules.pro
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── kotlin/com/srilanka/studyassistant/
│           │   └── MainActivity.kt
│           └── res/xml/
│               └── file_paths.xml
└── lib/
    ├── main.dart
    ├── app.dart
    ├── database/
    │   └── database_helper.dart
    ├── models/
    │   ├── note.dart
    │   ├── textbook.dart
    │   ├── past_paper.dart
    │   ├── flashcard.dart
    │   ├── quiz.dart
    │   ├── download_item.dart
    │   └── bookmark.dart
    ├── providers/
    │   ├── theme_provider.dart
    │   ├── language_provider.dart
    │   ├── notes_provider.dart
    │   ├── textbook_provider.dart
    │   ├── flashcard_provider.dart
    │   ├── quiz_provider.dart
    │   └── past_paper_provider.dart
    ├── services/
    │   ├── file_service.dart
    │   ├── ocr_service.dart
    │   ├── quiz_generator_service.dart
    │   ├── download_service.dart
    │   └── search_service.dart
    ├── screens/
    │   ├── main_navigation.dart
    │   ├── dashboard/dashboard_screen.dart
    │   ├── notes/notes_screen.dart
    │   ├── notes/note_reader_screen.dart
    │   ├── textbooks/textbooks_screen.dart
    │   ├── textbooks/textbook_reader_screen.dart
    │   ├── past_papers/past_papers_screen.dart
    │   ├── downloads/downloads_screen.dart
    │   ├── quiz/quiz_list_screen.dart
    │   ├── quiz/quiz_screen.dart
    │   ├── flashcards/flashcards_screen.dart
    │   ├── ocr/ocr_screen.dart
    │   ├── search/search_screen.dart
    │   └── settings/settings_screen.dart
    ├── widgets/
    │   ├── empty_state.dart
    │   ├── subject_chip.dart
    │   ├── loading_widget.dart
    │   └── stat_card.dart
    ├── localization/
    │   └── app_localizations.dart
    └── utils/
        ├── app_theme.dart
        ├── constants.dart
        └── helpers.dart
```

---

## SETUP INSTRUCTIONS

### Prerequisites
- Flutter SDK 3.10+  (https://docs.flutter.dev/get-started/install)
- Android Studio / VS Code
- Java 17+
- Android device or emulator (API 26+)

### Step 1 — Clone / Extract project
```bash
cd ~/projects
# Extract zip or copy folder here
cd sl_study_assistant
```

### Step 2 — Create required asset folders
```bash
mkdir -p assets/images assets/icons assets/lottie assets/fonts
```

### Step 3 — Download fonts
Download these free fonts from Google Fonts and put in `assets/fonts/`:
- NotoSansSinhala-Regular.ttf
- NotoSansSinhala-Bold.ttf
- NotoSansTamil-Regular.ttf
- NotoSansTamil-Bold.ttf

### Step 4 — Get dependencies
```bash
flutter pub get
```

### Step 5 — Run on device/emulator
```bash
# List available devices
flutter devices

# Run in debug mode
flutter run

# Run on a specific device
flutter run -d <device-id>
```

---

## APK BUILD INSTRUCTIONS

### Debug APK (for testing)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (for distribution)
```bash
# First, create a keystore (one time only):
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Create android/key.properties:
cat > android/key.properties << 'KEYEOF'
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to-keystore.jks>
KEYEOF

# Build release APK:
flutter build apk --release --split-per-abi

# Outputs:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← modern phones
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← older phones
# build/app/outputs/flutter-apk/app-x86_64-release.apk      ← emulators
```

### AAB (for Google Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## FEATURES IMPLEMENTED

| Feature | Status |
|---|---|
| Notes upload (PDF/TXT/DOCX) | ✅ |
| PDF Reader (SyncFusion) | ✅ |
| Textbooks with progress | ✅ |
| Past Papers library | ✅ |
| Download manager (pause/resume) | ✅ |
| OCR image-to-text | ✅ |
| AI Quiz Generator (rule-based) | ✅ |
| Quiz with timer & grading | ✅ |
| Flashcard decks + spaced repetition | ✅ |
| Full-text search | ✅ |
| Dark mode | ✅ |
| English / Sinhala / Tamil UI | ✅ |
| SQLite offline storage | ✅ |
| Bottom navigation | ✅ |
| Settings page | ✅ |

---

## NOTES FOR DEVELOPERS

- **OCR**: Tesseract language packs (sin, tam) must be bundled — see `tesseract_ocr` plugin docs
- **PDF Viewer**: SyncFusion community licence is free for individuals — register at syncfusion.com
- **Past Papers**: Replace `remoteUrl` values in `seedSamplePapers()` with real CDN URLs
- **Quiz Generation**: The rule-based engine works best on English text; extend `quiz_generator_service.dart` with a local LLM (e.g. llama.cpp via FFI) for smarter generation
