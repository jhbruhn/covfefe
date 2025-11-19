# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Covfefe** is a Flutter-based Android application with two main features:
1. **NFC Card Management**: Write and read NDEF records to/from NFC cards for the coffee tracking hardware
2. **Statistics Display**: Real-time coffee consumption statistics via BLE connection to the ESP32-S3 reader

## Project Type

Flutter mobile application (Android-focused, with NFC and BLE functionality)

## Project Structure

The main application code is located in the `app/` directory:
- **Package name**: `com.example.covfefe`
- **Flutter SDK**: 3.10.0+
- **Build system**: Kotlin DSL Gradle (build.gradle.kts)
- **Java compatibility**: JDK 17

### Current Implementation Status
- ✅ NFC card writing and reading functionality
- ✅ BLE statistics display with real-time updates
- ✅ Leaderboard display (consumption and cleaning)
- ✅ Connection state management and auto-reconnect
- ✅ Material Design 3 UI with dark mode support

## Key Technical Requirements

### NFC Functionality
- **Write exactly one NDEF Text Record per card** (UTF-8 encoding)
- **Read NDEF records from cards** for verification
- **Card types to provision**:
  - **Person cards**: NDEF text record containing person's name (e.g., "Alice")
  - **Special function cards**: NDEF text record with special identifier (e.g., "@@CLEAN@@")
- **User interface**:
  - Single text input for entering person names or custom values
  - Quick select buttons for special function cards (fills the text field)
  - Automatic card type detection based on `@@pattern@@` format
  - No predefined person list - all person names are entered manually

### BLE Statistics Functionality
- **Connect to ESP32-S3 coffee reader** via BLE (device name: "covfefe-reader")
- **Display real-time statistics**:
  - Total consumptions, cleanings, refills
  - Coffees since last cleaning/refill
  - Total registered users
  - Last cleaning/refill timestamps
- **Leaderboards**:
  - Coffee consumption leaderboard (sorted by count)
  - Cleaning leaderboard (sorted by count)
  - Each entry shows: rank, name, count, karma score, last activity
- **Real-time updates** via BLE notifications
- **Auto-reconnect** on connection loss
- **Binary data parsing** for leaderboard format (see BLE_CHARACTERISTICS.md)

### Flutter Setup
- Flutter SDK 3.10.0+ (configured in pubspec.yaml)
- Material Design 3 enabled
- Uses `flutter_lints` 6.0.0 for code quality
- **Key dependencies**:
  - `nfc_manager`: NFC card reading/writing
  - `flutter_reactive_ble`: BLE communication
  - `intl`: Date/time formatting
  - `permission_handler`: Runtime permission requests

## Development Commands

**Important**: All Flutter commands should be run from the `app/` directory.
**Flutter path**: `/home/jbruhn/flutter/flutter/bin/flutter`

### Initial Setup
```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter pub get
/home/jbruhn/flutter/flutter/bin/flutter doctor -v  # Verify Flutter installation
```

### Running the App
```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter run  # Run on connected Android device
/home/jbruhn/flutter/flutter/bin/flutter run -d <device-id>  # Run on specific device
/home/jbruhn/flutter/flutter/bin/flutter devices  # List available devices
```

### Building
```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter build apk --debug       # Build debug APK
/home/jbruhn/flutter/flutter/bin/flutter build apk --release     # Build release APK
/home/jbruhn/flutter/flutter/bin/flutter build appbundle --release  # Build app bundle for Play Store
```

### Testing
```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter test  # Run all tests
/home/jbruhn/flutter/flutter/bin/flutter test test/path/to/test_file.dart  # Run specific test
/home/jbruhn/flutter/flutter/bin/flutter test --coverage  # Run with coverage
```

### Code Quality
```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter analyze  # Analyze code (uses flutter_lints)
/home/jbruhn/flutter/flutter/bin/flutter format .  # Format code
/home/jbruhn/flutter/flutter/bin/flutter pub outdated  # Check for outdated dependencies
```

## Architecture Guidelines

### Current Structure
```
app/
├── android/                  # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle.kts  # App-level Gradle config
│   │   └── src/main/AndroidManifest.xml  # App manifest (NFC + BLE permissions)
│   └── build.gradle.kts      # Project-level Gradle config
├── ios/                      # iOS-specific configuration
│   └── Runner/
│       └── Info.plist        # iOS permissions (Bluetooth)
├── lib/
│   ├── main.dart             # App entry point with navigation
│   ├── models/               # Data models
│   │   ├── ble_constants.dart         # BLE UUIDs
│   │   ├── coffee_statistics.dart     # Statistics data model
│   │   ├── leaderboard_entry.dart     # Leaderboard entry model
│   │   └── special_cards.dart         # Special NFC card definitions
│   ├── services/             # Business logic services
│   │   ├── ble_statistics_service.dart  # BLE connection & data parsing
│   │   ├── nfc_reader_service.dart      # NFC reading logic
│   │   └── nfc_writer_service.dart      # NFC writing logic
│   ├── screens/              # UI screens
│   │   ├── read_card_screen.dart        # NFC card reading UI
│   │   ├── statistics_screen.dart       # BLE statistics UI
│   │   └── write_card_screen.dart       # NFC card writing UI
│   └── widgets/              # Reusable UI components
│       ├── connection_status_banner.dart  # BLE status indicator
│       ├── leaderboard_list_item.dart     # Leaderboard entry widget
│       ├── nfc_status_banner.dart         # NFC status indicator
│       └── statistic_card.dart            # Statistics card widget
├── pubspec.yaml              # Flutter dependencies
├── CLAUDE.md                 # AI assistant guidance
└── QUICKSTART.md             # Quick start guide
```

### State Management
Uses StatefulWidget with StreamController for:
- BLE connection state and statistics updates
- NFC operation status
- UI state management

### NFC Implementation Notes
- Always check NFC availability on app startup
- Handle NFC disabled state gracefully with clear user instructions
- Implement proper error handling for write failures (card not writable, insufficient memory, etc.)
- NDEF text records should use UTF-8 encoding
- Include user feedback (success/error messages, haptic feedback, visual confirmation)
- Clear previous NDEF records before writing new ones to avoid conflicts

### BLE Implementation Notes
- Device name to scan for: "covfefe-reader"
- Service UUID: `c0ffee00-0000-1000-8000-00805f9b34fb`
- All numeric values are little-endian encoded
- Leaderboard binary format: `[count:4][karma:4][timestamp:4][name_len:1][name:name_len]`
- Subscribe to statistics characteristics for real-time updates
- Implement auto-reconnect on connection loss
- **Runtime permissions**: Request Bluetooth permissions before scanning (handled automatically)
- Handle BLE permissions (different for Android 12+ vs older versions)
- See `BLE_CHARACTERISTICS.md` in root directory for full specification

### Android Configuration

**Manifest location**: `app/android/app/src/main/AndroidManifest.xml`

Permissions already configured:
```xml
<!-- NFC -->
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />

<!-- Bluetooth (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Bluetooth (older Android) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

**Gradle configuration**:
- App-level: `app/android/app/build.gradle.kts`
- Current minSdk is set by Flutter (likely 21+), supports both NFC and BLE APIs
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

### NFC Testing
- Unit tests for NDEF record creation
- Widget tests for UI components
- Manual testing on physical Android device with NFC cards (required)
- Test with various NFC card types (NTAG213/215/216, Mifare Ultralight recommended)

### BLE Testing
- Unit tests for binary leaderboard parsing
- Widget tests for statistics screen components
- Manual testing with ESP32-S3 coffee reader device
- Test connection/disconnection scenarios
- Test real-time updates via notifications
- Test auto-reconnect functionality
- Verify leaderboard sorting and display

## Important Notes
- NFC write functionality requires physical Android device (emulator not supported)
- BLE functionality requires physical device with Bluetooth LE support
- Test with actual NFC cards that support NDEF format
- Ensure cards are writable (not locked)
- Ensure ESP32-S3 reader is powered on and advertising as "covfefe-reader"
- BLE range is approximately 10 meters
- App automatically reconnects to BLE device on connection loss
- Statistics update in real-time via BLE notifications
