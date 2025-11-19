# Covfefe Flutter App - Quick Start Guide

## Overview

The Covfefe Flutter app is used for:
1. **NFC Card Management**: Write and read NFC cards for the coffee tracking system
2. **Statistics Display**: View real-time coffee consumption statistics via BLE from the ESP32-S3 reader

## Prerequisites

- Flutter SDK 3.10.0+
- Android device with NFC and Bluetooth LE support
- Physical NFC cards (NTAG213/215/216 or Mifare Ultralight)
- Covfefe coffee reader device (ESP32-S3 with BLE)

## Installation

### 1. Install Dependencies

```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter pub get
```

### 2. Run the App

```bash
# Connect your Android device via USB
/home/jbruhn/flutter/flutter/bin/flutter devices

# Run the app
/home/jbruhn/flutter/flutter/bin/flutter run
```

## Features

### Manage Cards Tab

**Write Card Mode:**
- Enter a person's name or select a special function (e.g., @@CLEAN@@)
- Tap "Write to Card" and hold an NFC card to the device
- The app writes an NDEF text record with the entered value

**Read Card Mode:**
- Tap "Read Card" and hold an NFC card to the device
- View the card's NDEF content and type (Person or Special Function)

### Statistics Tab

**Real-time BLE Statistics:**
- Automatically scans for and connects to the "covfefe-reader" BLE device
- Displays overall statistics:
  - Total coffees consumed
  - Total cleanings performed
  - Total refills
  - Number of registered users
- Shows maintenance info:
  - Coffees since last cleaning
  - Coffees since last refill
  - Timestamps of last cleaning/refill
- Leaderboards:
  - Coffee consumption leaderboard (sorted by count)
  - Cleaning leaderboard (sorted by count)
  - Each entry shows: rank, name, count, karma score, and last activity time
- Pull-to-refresh to reconnect
- Real-time updates via BLE notifications

## Permissions

The app requires the following permissions:

**Android:**
- NFC (for card reading/writing)
- Bluetooth (for statistics display)
- Location (required for BLE scanning on older Android versions)

**iOS:**
- Bluetooth (for statistics display)

Permissions will be requested when you first use each feature.

## BLE Connection

The statistics screen automatically:
1. Requests Bluetooth permissions (if not already granted)
2. Scans for the "covfefe-reader" BLE device
3. Connects when found
4. Reads all statistics and leaderboard data
5. Subscribes to notifications for real-time updates
6. Automatically reconnects if connection is lost

**Permissions Requested:**
- Bluetooth Scan (Android 12+)
- Bluetooth Connect (Android 12+)
- Location (older Android versions - required for BLE scanning)

**Connection States:**
- **Scanning**: Looking for the coffee reader device
- **Connecting**: Establishing connection
- **Connected**: Successfully connected and receiving data
- **Disconnected**: Not connected (tap Retry to reconnect)

## Troubleshooting

### BLE Connection Issues

1. **Device not found:**
   - Ensure the ESP32-S3 reader is powered on
   - Check that BLE is enabled on your phone
   - Verify the device is advertising as "covfefe-reader"
   - Try pull-to-refresh on the statistics screen

2. **Connection drops:**
   - The app will automatically attempt to reconnect
   - Ensure you're within BLE range (~10 meters)
   - Check for interference from other devices

3. **Permissions denied:**
   - Go to Settings > Apps > Covfefe > Permissions
   - Enable Bluetooth and Location permissions

### NFC Issues

1. **Card not detected:**
   - Ensure NFC is enabled on your device
   - Hold the card flat against the back of your phone
   - Try different positions on the back of the device

2. **Write failed:**
   - Ensure the card is writable (not locked)
   - Use NDEF-compatible cards (NTAG213/215/216 recommended)
   - Try a different card

## Development

### Build APK

```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter build apk --release
```

The APK will be located at: `app/build/app/outputs/flutter-apk/app-release.apk`

### Run Tests

```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter test
```

### Code Analysis

```bash
cd app
/home/jbruhn/flutter/flutter/bin/flutter analyze
```

## Project Structure

```
app/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── ble_constants.dart             # BLE UUIDs
│   │   ├── coffee_statistics.dart         # Statistics data model
│   │   ├── leaderboard_entry.dart         # Leaderboard entry model
│   │   └── special_cards.dart             # Special NFC card definitions
│   ├── screens/
│   │   ├── read_card_screen.dart          # NFC card reading UI
│   │   ├── statistics_screen.dart         # BLE statistics UI
│   │   └── write_card_screen.dart         # NFC card writing UI
│   ├── services/
│   │   ├── ble_statistics_service.dart    # BLE connection & data parsing
│   │   ├── nfc_reader_service.dart        # NFC reading logic
│   │   └── nfc_writer_service.dart        # NFC writing logic
│   └── widgets/
│       ├── connection_status_banner.dart  # BLE status indicator
│       ├── leaderboard_list_item.dart     # Leaderboard entry widget
│       ├── nfc_status_banner.dart         # NFC status indicator
│       └── statistic_card.dart            # Statistics card widget
├── android/                               # Android-specific config
├── ios/                                   # iOS-specific config
└── pubspec.yaml                           # Dependencies
```

## Key Dependencies

- `nfc_manager`: NFC card reading/writing
- `flutter_reactive_ble`: BLE communication
- `intl`: Date/time formatting
- `permission_handler`: Runtime permission requests

## BLE Characteristics

See [BLE_CHARACTERISTICS.md](../BLE_CHARACTERISTICS.md) in the root directory for detailed information about the BLE service and characteristics exposed by the ESP32-S3 coffee reader.

## Notes

- The app is primarily designed for Android (NFC write functionality requires physical device)
- Statistics update in real-time when connected to the coffee reader
- Leaderboards are sorted by count (highest first)
- Karma score formula: `(cleanings × 10) - (coffees × 0.5)`
