import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

/// Result of reading an NFC card
class NfcReadResult {
  final String? text;
  final CardTypeNfc cardType;
  final List<String> allRecords;

  NfcReadResult({
    required this.text,
    required this.cardType,
    required this.allRecords,
  });
}

enum CardTypeNfc { person, specialFunction, unknown, empty }

/// Service for reading NDEF Text Records from NFC cards
class NfcReaderService {
  /// Check if NFC is available on this device
  static Future<bool> isNfcAvailable() async {
    NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Parse NDEF Text Record payload
  static String? parseTextRecord(NdefRecord record) {
    try {
      // NDEF Text Record format:
      // - Type: "T" (0x54)
      // - Payload: [status byte][language code][text]

      if (record.typeNameFormat != TypeNameFormat.wellKnown) {
        return null;
      }

      // Check if this is a Text record (type "T" = 0x54)
      if (record.type.length != 1 || record.type[0] != 0x54) {
        return null;
      }

      final payload = record.payload;
      if (payload.isEmpty) {
        return null;
      }

      // First byte is status byte (encoding + language code length)
      final statusByte = payload[0];
      final languageCodeLength = statusByte & 0x3F; // Lower 6 bits

      if (payload.length < 1 + languageCodeLength) {
        return null;
      }

      // Skip status byte and language code to get to the text
      final textBytes = payload.sublist(1 + languageCodeLength);

      // Decode as UTF-8
      return utf8.decode(textBytes);
    } catch (e) {
      return null;
    }
  }

  /// Determine card type from text
  static CardTypeNfc getCardType(String? text) {
    if (text == null || text.isEmpty) {
      return CardTypeNfc.empty;
    }
    if (text.startsWith('@@') && text.endsWith('@@')) {
      return CardTypeNfc.specialFunction;
    }
    return CardTypeNfc.person;
  }

  /// Read NDEF records from an NFC card
  ///
  /// [onSuccess] - Callback when read succeeds with the result
  /// [onError] - Callback when read fails with error message
  static Future<void> readCard({
    required Function(NfcReadResult result) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      // Check if NFC is available
      bool isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        onError('NFC is not available on this device');
        return;
      }

      // Start NFC session
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            // Get cross-platform NDEF instance
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Tag is not NDEF formatted');
              await NfcManager.instance.stopSession(
                errorMessageIos: 'Tag is not NDEF formatted',
              );
              return;
            }

            // Read the cached message
            final ndefMessage = ndef.cachedMessage;
            if (ndefMessage == null) {
              onError('No NDEF message found on card');
              await NfcManager.instance.stopSession(
                errorMessageIos: 'No NDEF message found on card',
              );
              return;
            }

            // Parse all records
            List<String> allRecords = [];
            String? primaryText;

            for (var record in ndefMessage.records) {
              final text = parseTextRecord(record);
              if (text != null) {
                allRecords.add(text);
                // Use the first text record as primary
                primaryText ??= text;
              }
            }

            if (allRecords.isEmpty) {
              onError('No text records found on card');
              await NfcManager.instance.stopSession(
                errorMessageIos: 'No text records found on card',
              );
              return;
            }

            // Determine card type
            final cardType = getCardType(primaryText);

            // Success!
            await NfcManager.instance.stopSession(
              alertMessageIos: 'Card read successfully!',
            );
            onSuccess(
              NfcReadResult(
                text: primaryText,
                cardType: cardType,
                allRecords: allRecords,
              ),
            );
          } catch (e) {
            onError('Failed to read: ${e.toString()}');
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Failed to read: ${e.toString()}',
            );
          }
        },
      );
    } catch (e) {
      onError('Failed to start NFC session: ${e.toString()}');
    }
  }

  /// Cancel ongoing NFC session
  static Future<void> cancelSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors when canceling
    }
  }
}
