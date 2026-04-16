# Knowvas Flutter Client

A cross-platform mobile and desktop application for digital content reading, providing a native, high-performance experience for ebooks (EPUB), PDFs, comics, magazines, and audiobooks. Built with Flutter for the application shell and native modules (Kotlin/Swift) for optimized reader functionality.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [Flutter Setup](#flutter-setup)
  - [Android Setup](#android-setup)
  - [iOS Setup](#ios-setup)
- [Running the App](#running-the-app)
- [Building for Production](#building-for-production)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

Knowvas Flutter Client is a production-grade mobile application that interfaces with the Knowvas Flask backend to deliver a seamless reading experience. The app leverages platform-specific capabilities for optimal performance while maintaining code reusability across platforms.

### Key Highlights

- **Hybrid Architecture**: Flutter handles UI/navigation/state, native modules handle rendering
- **Offline-First**: Download content for offline reading with encrypted storage
- **High Performance**: Lazy loading, memory management, and efficient rendering for large files
- **Secure**: JWT authentication, encrypted file storage, certificate validation
- **Feature-Rich**: Social features, reading goals, achievements, bookmarks, highlights, and more

## 🏗️ Architecture

The app uses a hybrid architecture that separates concerns for optimal performance:

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Layer                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │    UI    │  │   State  │  │Navigation│  │ Network │ │
│  │Components│  │Management│  │go_router │  │   Dio   │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Platform Channel (Method + Event)        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                    ┌────────▼────────┐
│ Native Android │                    │   Native iOS    │
│    (Kotlin)    │                    │    (Swift)      │
├────────────────┤                    ├─────────────────┤
│ • EPUB Reader  │                    │ • EPUB Reader   │
│   (Readium)    │                    │   (Readium)     │
│ • PDF Reader   │                    │ • PDF Reader    │
│   (PdfRenderer)│                    │   (PDFKit)      │
│ • Comic Reader │                    │ • Comic Reader  │
│   (Image Seq)  │                    │   (Image Seq)   │
└────────────────┘                    └─────────────────┘
```

### Technology Stack

**Flutter Layer:**
- Flutter 3.7+ / Dart 3.0+
- State Management: Riverpod
- Navigation: go_router
- HTTP Client: Dio
- Local Storage: sqflite, flutter_secure_storage

**Android Native:**
- Kotlin 1.9+
- Min SDK: 24 (Android 7.0)
- EPUB: Readium Mobile Android
- PDF: Android PdfRenderer
- Image Loading: Coil

**iOS Native:**
- Swift 5.7+
- Min iOS: 14.0
- EPUB: Readium Mobile iOS
- PDF: PDFKit
- Image Loading: Kingfisher

## ✨ Features

- **Authentication**: Secure JWT-based authentication with token refresh
- **Content Discovery**: Browse featured, bestsellers, new releases, and trending content
- **Search & Filters**: Advanced search with genre, price, rating, and language filters
- **Library Management**: Organize content with collections, favorites, and reading progress
- **Native Readers**: 
  - EPUB with customizable fonts, themes, and text-to-speech
  - PDF with zoom, pan, and annotation support
  - Comics with panel navigation and guided view
- **Offline Reading**: Download and encrypt content for offline access
- **Social Features**: Follow authors, rate content, write reviews
- **Reading Goals**: Set and track reading goals with achievements
- **Engagement Tracking**: Automatic progress sync and analytics
- **Multi-Currency**: Support for NGN, USD, and other currencies
- **Subscriptions**: Manage premium subscriptions and access

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

### Required

- **Flutter SDK**: 3.7.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.0.0 or higher (included with Flutter)
- **Git**: For version control

### For Android Development

- **Android Studio**: Arctic Fox or higher
- **Android SDK**: API Level 24 (Android 7.0) or higher
- **Java Development Kit (JDK)**: 11 or higher
- **Kotlin**: 1.9+ (included with Android Studio)

### For iOS Development (macOS only)

- **Xcode**: 14.0 or higher
- **CocoaPods**: 1.11.0 or higher (`sudo gem install cocoapods`)
- **iOS Simulator** or physical iOS device

### Optional

- **VS Code** with Flutter/Dart extensions
- **Android Emulator** or physical Android device
- **Firebase CLI** (if using Firebase services)

## 🚀 Setup Instructions

### Flutter Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/knowvas-flutter-client.git
   cd knowvas-flutter-client
   ```

2. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```
   Resolve any issues reported by `flutter doctor`.

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run code generation** (for Riverpod, Freezed, JSON serialization)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Configure environment variables**
   
   Create a `.env` file in the project root:
   ```env
   API_BASE_URL=https://api.knowvas.com
   API_TIMEOUT=30000
   ENABLE_LOGGING=true
   ```

### Android Setup

1. **Open Android project in Android Studio**
   ```bash
   cd android
   open -a "Android Studio" .
   ```

2. **Configure Gradle**
   
   Ensure `android/build.gradle` has the correct Kotlin version:
   ```gradle
   buildscript {
       ext.kotlin_version = '1.9.0'
       // ...
   }
   ```

3. **Sync Gradle dependencies**
   
   In Android Studio: `File > Sync Project with Gradle Files`

4. **Add Readium dependencies**
   
   In `android/app/build.gradle`:
   ```gradle
   dependencies {
       implementation "org.readium.kotlin-toolkit:readium-shared:2.4.0"
       implementation "org.readium.kotlin-toolkit:readium-streamer:2.4.0"
       implementation "org.readium.kotlin-toolkit:readium-navigator:2.4.0"
       // Other dependencies...
   }
   ```

5. **Configure signing** (for release builds)
   
   Create `android/key.properties`:
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=<your-key-alias>
   storeFile=<path-to-keystore>
   ```

6. **Set minimum SDK version**
   
   In `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           minSdkVersion 24
           targetSdkVersion 34
       }
   }
   ```

### iOS Setup

1. **Install CocoaPods dependencies**
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Open iOS project in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Configure signing**
   
   In Xcode:
   - Select `Runner` project
   - Go to `Signing & Capabilities`
   - Select your development team
   - Ensure bundle identifier is unique

4. **Add Readium dependencies**
   
   In `ios/Podfile`:
   ```ruby
   target 'Runner' do
     use_frameworks!
     use_modular_headers!
     
     pod 'R2Shared', '~> 2.4.0'
     pod 'R2Streamer', '~> 2.4.0'
     pod 'R2Navigator', '~> 2.4.0'
     pod 'Kingfisher', '~> 7.0'
     
     flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
   end
   ```

5. **Set deployment target**
   
   In Xcode or `ios/Podfile`:
   ```ruby
   platform :ios, '14.0'
   ```

6. **Update Info.plist permissions**
   
   Add required permissions in `ios/Runner/Info.plist`:
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>To save images from content</string>
   <key>NSCameraUsageDescription</key>
   <string>To capture profile pictures</string>
   ```

## 🏃 Running the App

### Development Mode

**Run on connected device/emulator:**
```bash
flutter run
```

**Run on specific device:**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

**Run with specific flavor (if configured):**
```bash
flutter run --flavor dev
flutter run --flavor staging
flutter run --flavor production
```

**Hot reload:**
Press `r` in the terminal while the app is running.

**Hot restart:**
Press `R` in the terminal while the app is running.

### Debug Mode

```bash
flutter run --debug
```

### Profile Mode (for performance testing)

```bash
flutter run --profile
```

### Release Mode

```bash
flutter run --release
```

## 📱 Building for Production

### Android

**Build APK (for testing):**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Build App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**Build with specific flavor:**
```bash
flutter build appbundle --release --flavor production
```

### iOS

**Build for device:**
```bash
flutter build ios --release
```

**Create archive in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Product > Archive`
3. Once archived, click `Distribute App`
4. Follow the wizard to upload to App Store Connect

**Build IPA (command line):**
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/`

## 📂 Project Structure

```
knowvas_flutter_client/
├── android/                    # Android native code
│   └── app/src/main/kotlin/
│       └── com/knowvas/reader/
│           ├── ReaderPlugin.kt
│           ├── epub/          # EPUB reader module
│           ├── pdf/           # PDF reader module
│           └── comic/         # Comic reader module
├── ios/                       # iOS native code
│   └── Runner/Reader/
│       ├── ReaderPlugin.swift
│       ├── Epub/             # EPUB reader module
│       ├── Pdf/              # PDF reader module
│       └── Comic/            # Comic reader module
├── lib/
│   ├── app/                  # Application root
│   │   ├── app.dart
│   │   └── router.dart
│   ├── core/                 # Core functionality
│   │   ├── constants/
│   │   ├── database/
│   │   ├── download/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── platform/         # Platform channel wrappers
│   │   ├── security/
│   │   ├── sync/
│   │   └── utils/
│   ├── features/             # Feature modules
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       └── widgets/
│   │   ├── cart/
│   │   ├── discover/
│   │   ├── library/
│   │   ├── profile/
│   │   ├── reader/
│   │   ├── settings/
│   │   └── social/
│   └── shared/               # Shared resources
│       ├── models/
│       ├── providers/
│       └── widgets/
├── test/                     # Unit and widget tests
├── integration_test/         # Integration tests
├── analysis_options.yaml     # Linting rules
├── pubspec.yaml             # Dependencies
└── README.md
```

### Architecture Layers

Each feature follows clean architecture:
- **Data Layer**: API clients, repositories, models, data sources
- **Domain Layer**: Business logic, use cases, entities (optional)
- **Presentation Layer**: UI screens, widgets, state providers (Riverpod)

## 🧪 Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/features/auth/auth_repository_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

View coverage report:
```bash
# Install lcov (macOS)
brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Run Integration Tests

```bash
flutter test integration_test/
```

### Run Android Instrumented Tests

```bash
cd android
./gradlew connectedAndroidTest
```

### Run iOS Tests

```bash
cd ios
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Linting and Formatting

**Analyze code:**
```bash
flutter analyze
```

**Format code:**
```bash
flutter format lib/ test/
```

**Check formatting:**
```bash
flutter format --set-exit-if-changed lib/ test/
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues

**Problem**: `flutter doctor` shows errors

**Solution**:
- Follow the specific instructions provided by `flutter doctor`
- Ensure all required tools are installed and in PATH
- Run `flutter doctor -v` for detailed diagnostics

#### 2. Build Runner Conflicts

**Problem**: Code generation fails with conflicts

**Solution**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. Android Build Fails

**Problem**: Gradle sync or build errors

**Solutions**:
- Clean build: `flutter clean && flutter pub get`
- Invalidate caches in Android Studio: `File > Invalidate Caches / Restart`
- Check Kotlin version compatibility
- Ensure `minSdkVersion` is 24 or higher
- Update Gradle: `cd android && ./gradlew wrapper --gradle-version=8.0`

#### 4. iOS Build Fails

**Problem**: CocoaPods or Xcode build errors

**Solutions**:
- Update CocoaPods: `sudo gem install cocoapods`
- Clean pods: `cd ios && rm -rf Pods Podfile.lock && pod install`
- Clean Xcode build: `cd ios && xcodebuild clean`
- Ensure deployment target is iOS 14.0+
- Check signing certificates in Xcode

#### 5. Platform Channel Errors

**Problem**: Native reader fails to open

**Solutions**:
- Check native logs:
  - Android: `adb logcat | grep Flutter`
  - iOS: View logs in Xcode Console
- Verify platform channel names match between Flutter and native code
- Ensure native dependencies (Readium) are properly installed
- Check file permissions and paths

#### 6. Memory Issues with Large Files

**Problem**: App crashes when opening large EPUBs/PDFs

**Solutions**:
- Verify lazy loading is implemented in native readers
- Check memory management in `MemoryManager.kt` / `MemoryManager.swift`
- Test on physical devices (emulators have limited memory)
- Monitor memory usage with profiling tools

#### 7. Network/API Errors

**Problem**: API calls fail or timeout

**Solutions**:
- Verify API base URL in `.env` file
- Check network connectivity
- Verify JWT tokens are being sent correctly
- Check backend API is running and accessible
- Review Dio interceptor logs
- Test with tools like Postman to isolate issues

#### 8. Encryption/Storage Errors

**Problem**: Downloaded files fail to decrypt

**Solutions**:
- Clear app data and re-authenticate
- Verify encryption keys are stored in secure storage
- Check file permissions
- Ensure sufficient storage space
- Review encryption service logs

#### 9. State Management Issues

**Problem**: UI not updating or state inconsistencies

**Solutions**:
- Verify Riverpod providers are properly configured
- Check provider dependencies
- Use `ref.invalidate()` to force refresh
- Review state mutation logic
- Enable Riverpod logging for debugging

#### 10. Hot Reload Not Working

**Problem**: Changes not reflecting after hot reload

**Solutions**:
- Try hot restart (press `R`)
- Restart the app completely
- Check for syntax errors
- Some changes (like native code) require full rebuild

### Getting Help

If you encounter issues not covered here:

1. **Check logs**: Use `flutter logs` or native platform logs
2. **Search issues**: Check GitHub issues for similar problems
3. **Documentation**: Review Flutter and Readium documentation
4. **Ask the team**: Contact the development team on Slack/Discord
5. **Create an issue**: Open a GitHub issue with:
   - Flutter version (`flutter --version`)
   - Device/OS information
   - Steps to reproduce
   - Error logs and stack traces

### Useful Commands

```bash
# Clear all build artifacts
flutter clean

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Repair pub cache
flutter pub cache repair

# View device logs
flutter logs

# Take screenshot
flutter screenshot

# Attach to running app
flutter attach
```

## 🤝 Contributing

### Development Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "Add feature"`
3. Run tests: `flutter test`
4. Run linting: `flutter analyze`
5. Format code: `flutter format lib/ test/`
6. Push branch: `git push origin feature/your-feature`
7. Create Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use the linting rules in `analysis_options.yaml`
- Write meaningful commit messages
- Add tests for new features
- Document public APIs with dartdoc comments

### Pull Request Guidelines

- Provide clear description of changes
- Reference related issues
- Ensure all tests pass
- Update documentation if needed
- Request review from team members

## 📄 License

Proprietary - All rights reserved

---

**Built with ❤️ by the Knowvas Team**

For more information, visit [knowvas.com](https://knowvas.com) or contact support@knowvas.com
