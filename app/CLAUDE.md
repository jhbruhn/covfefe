# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Covfefe** is a Flutter-based Android application for writing NDEF records to NFC cards. These cards are used with separate coffee tracking hardware. The app's sole purpose is to provision NFC cards by writing specific NDEF text records.

## Project Type

Flutter mobile application (Android-focused, NFC write functionality only)

## Project Structure

The main application code is located in the `covfefe/` directory:
- **Package name**: `com.example.covfefe`
- **Flutter SDK**: 3.10.0+
- **Build system**: Kotlin DSL Gradle (build.gradle.kts)
- **Java compatibility**: JDK 17

### Current Implementation Status
- Base Flutter project created with Hello World app (covfefe/lib/main.dart:15)
- No NFC functionality implemented yet
- No dependencies added beyond flutter_lints
- Android manifest does not include NFC permissions yet
- Material Design scaffold ready for UI implementation

## Key Technical Requirements

### NFC Functionality
- **Write exactly one NDEF Text Record per card** (UTF-8 encoding)
- **No reading/tracking functionality** - this app only provisions cards
- **Card types to provision**:
  - **Person cards**: NDEF text record containing person's name (e.g., "Alice")
  - **Special function cards**: NDEF text record with special identifier (e.g., "@@CLEAN@@")
- **User interface**:
  - Single text input for entering person names or custom values
  - Quick select buttons for special function cards (fills the text field)
  - Automatic card type detection based on `@@pattern@@` format
  - No predefined person list - all person names are entered manually

### Flutter Setup (Current Configuration)
- Flutter SDK 3.10.0+ (configured in pubspec.yaml)
- Material Design enabled
- Uses `flutter_lints` 6.0.0 for code quality
- **NFC package needed**: Add `nfc_manager` or `flutter_nfc_kit` to pubspec.yaml dependencies

## Development Commands

**Important**: All Flutter commands should be run from the `covfefe/` directory.

### Initial Setup
```bash
cd covfefe
flutter pub get
flutter doctor -v  # Verify Flutter installation
```

### Running the App
```bash
cd covfefe
flutter run  # Run on connected Android device
flutter run -d <device-id>  # Run on specific device
flutter devices  # List available devices
```

### Building
```bash
cd covfefe
flutter build apk --debug       # Build debug APK
flutter build apk --release     # Build release APK
flutter build appbundle --release  # Build app bundle for Play Store
```

### Testing
```bash
cd covfefe
flutter test  # Run all tests
flutter test test/path/to/test_file.dart  # Run specific test
flutter test --coverage  # Run with coverage
```

### Code Quality
```bash
cd covfefe
flutter analyze  # Analyze code (uses flutter_lints)
flutter format .  # Format code
flutter pub outdated  # Check for outdated dependencies
```

## Architecture Guidelines

### Current Structure
```
covfefe/
├── android/                  # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle.kts  # App-level Gradle config
│   │   └── src/main/AndroidManifest.xml  # App manifest
│   └── build.gradle.kts      # Project-level Gradle config
├── lib/
│   └── main.dart             # App entry point (currently Hello World)
├── pubspec.yaml              # Flutter dependencies
└── README.md
```

### Planned Structure for NFC Implementation
```
covfefe/lib/
├── main.dart                 # App entry point
├── models/                   # Data models (CardType, etc.)
├── services/                 # NFC service
│   └── nfc_writer_service.dart  # Core NFC write logic
├── screens/                  # UI screens
│   └── card_writer_screen.dart  # Main interface
├── widgets/                  # Reusable UI components
└── constants/                # Pre-defined users/functions
    └── card_types.dart
```

### State Management
Use a lightweight state management solution (Provider or Riverpod) for managing:
- Selected user/function
- NFC write operation status
- Text input state

### NFC Implementation Notes
- Always check NFC availability on app startup
- Handle NFC disabled state gracefully with clear user instructions
- Implement proper error handling for write failures (card not writable, insufficient memory, etc.)
- NDEF text records should use UTF-8 encoding
- Include user feedback (success/error messages, haptic feedback, visual confirmation)
- Clear previous NDEF records before writing new ones to avoid conflicts

### Android Configuration

**Manifest location**: `covfefe/android/app/src/main/AndroidManifest.xml`

Add NFC permissions before the `<application>` tag:
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />
```

**Gradle configuration**:
- App-level: `covfefe/android/app/build.gradle.kts`
- Current minSdk is set by Flutter (likely 21+), verify this supports NFC APIs
- Namespace: `com.example.covfefe`

## Card Types and NDEF Structure

All cards contain **exactly one NDEF Text Record** with UTF-8 encoding. There are two types:

### Person Cards
- **Purpose**: Track coffee consumption for a specific person
- **NDEF Content**: The person's name (e.g., "Alice", "Bob", "John Doe")
- **Example**: `Alice` → One NDEF Text record containing "Alice"

### Special Function Cards
- **Purpose**: Trigger special actions (not person consumption tracking)
- **NDEF Content**: Special identifier in format `@@FUNCTION@@`
- **Currently Defined**:
  - **Cleaning Card**: `@@CLEAN@@` - Triggers cleaning record instead of consumption
- **Format Rule**: Must start and end with `@@`

### Card Provisioning Workflow
1. User enters person name in text field OR taps a special function button to auto-fill
2. App shows card type (Person or Special Function based on `@@` pattern)
3. User taps "Write to Card" button
4. User taps NFC card to phone when prompted
5. App writes exactly one NDEF Text Record (UTF-8) with the entered value
6. App confirms success/failure with visual feedback
7. Text field auto-clears for next card

## Testing Strategy
- Unit tests for NDEF record creation
- Widget tests for UI components
- Manual testing on physical Android device with NFC cards (required)
- Test with various NFC card types (NTAG213/215/216, Mifare Ultralight recommended)

## Important Notes
- NFC write functionality requires physical Android device (emulator not supported)
- Test with actual NFC cards that support NDEF format
- Ensure cards are writable (not locked)
- App scope is intentionally limited to card provisioning only
- Future expansion may include consumption tracking features
