import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

/// Service for writing NDEF Text Records to NFC cards
class NfcWriterService {
  /// Check if NFC is available on this device
  static Future<bool> isNfcAvailable() async {
    NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Create an NDEF Text Record
  static NdefRecord createTextRecord(String text) {
    // NDEF Text Record format:
    // - Type: "T" (0x54)
    // - Payload: [status byte][language code][text]
    //   - status byte: 0x02 for UTF-8 encoding, 2-byte language code length
    //   - language code: "en"
    //   - text: UTF-8 encoded text

    final languageCode = 'en';
    final languageCodeBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);

    // Status byte: UTF-8 encoding (bit 7=0) + language code length
    final statusByte = languageCodeBytes.length;

    // Build payload
    final payload = Uint8List(1 + languageCodeBytes.length + textBytes.length);
    payload[0] = statusByte;
    payload.setRange(1, 1 + languageCodeBytes.length, languageCodeBytes);
    payload.setRange(1 + languageCodeBytes.length, payload.length, textBytes);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // "T"
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Write a single NDEF Text Record to an NFC card
  ///
  /// [text] - The text to write (person name or special function like "@@CLEAN@@")
  /// [onSuccess] - Callback when write succeeds
  /// [onError] - Callback when write fails with error message
  static Future<void> writeTextRecord({
    required String text,
    required Function() onSuccess,
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
            // Create NDEF Text Record with UTF-8 encoding
            final textRecord = createTextRecord(text);

            // Create NDEF message with single record
            final ndefMessage = NdefMessage(records: [textRecord]);

            // Write NDEF message to tag using cross-platform API
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Tag is not NDEF formatted');
              await NfcManager.instance.stopSession(
                errorMessageIos: 'Tag is not NDEF formatted',
              );
              return;
            }

            // Check if tag is writable
            if (!ndef.isWritable) {
              onError('Tag is not writable (locked)');
              await NfcManager.instance.stopSession(
                errorMessageIos: 'Tag is not writable (locked)',
              );
              return;
            }

            // Check if message fits on the tag
            int messageSize = ndefMessage.byteLength;
            int maxSize = ndef.maxSize;

            if (messageSize > maxSize) {
              final errorMsg =
                  'Text too long for this card ($messageSize bytes > $maxSize bytes)';
              onError(errorMsg);
              await NfcManager.instance.stopSession(errorMessageIos: errorMsg);
              return;
            }

            // Write to tag
            await ndef.write(message: ndefMessage);

            // Success!
            await NfcManager.instance.stopSession(
              alertMessageIos: 'Card written successfully!',
            );
            onSuccess();
          } catch (e) {
            onError('Failed to write: ${e.toString()}');
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Failed to write: ${e.toString()}',
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
