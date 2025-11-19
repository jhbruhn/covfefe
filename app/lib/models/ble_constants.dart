// BLE UUIDs and constants for the Covfefe Coffee Reader
// Based on BLE_CHARACTERISTICS.md specification

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  // Device name
  static const String deviceName = 'covfefe-reader';

  // Service UUID
  static final Uuid serviceUuid = Uuid.parse('c0ffee00-0000-1000-8000-00805f9b34fb');

  // Statistics Characteristics (with Notifications)
  static final Uuid totalConsumptionsUuid = Uuid.parse('c0ffee01-0000-1000-8000-00805f9b34fb');
  static final Uuid totalCleaningsUuid = Uuid.parse('c0ffee02-0000-1000-8000-00805f9b34fb');
  static final Uuid totalRefillsUuid = Uuid.parse('c0ffee03-0000-1000-8000-00805f9b34fb');
  static final Uuid coffeesSinceCleaningUuid = Uuid.parse('c0ffee04-0000-1000-8000-00805f9b34fb');
  static final Uuid coffeesSinceRefillUuid = Uuid.parse('c0ffee05-0000-1000-8000-00805f9b34fb');
  static final Uuid totalUsersUuid = Uuid.parse('c0ffee06-0000-1000-8000-00805f9b34fb');

  // Leaderboard Characteristics (Read-only)
  static final Uuid consumptionLeaderboardUuid = Uuid.parse('c0ffee07-0000-1000-8000-00805f9b34fb');
  static final Uuid cleaningLeaderboardUuid = Uuid.parse('c0ffee08-0000-1000-8000-00805f9b34fb');

  // Timestamp Characteristics (Read-only)
  static final Uuid lastCleaningTimeUuid = Uuid.parse('c0ffee09-0000-1000-8000-00805f9b34fb');
  static final Uuid lastRefillTimeUuid = Uuid.parse('c0ffee0a-0000-1000-8000-00805f9b34fb');
}
