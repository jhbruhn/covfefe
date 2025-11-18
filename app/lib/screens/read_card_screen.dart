import 'package:flutter/material.dart';
import '../services/nfc_reader_service.dart';
import '../widgets/nfc_status_banner.dart';
import '../models/special_cards.dart';

/// Screen for reading NDEF Text Records from NFC cards
class ReadCardScreen extends StatefulWidget {
  final bool nfcAvailable;

  const ReadCardScreen({super.key, required this.nfcAvailable});

  @override
  State<ReadCardScreen> createState() => _ReadCardScreenState();
}

class _ReadCardScreenState extends State<ReadCardScreen> {
  ReadStatus _readStatus = ReadStatus.idle;
  NfcReadResult? _readResult;
  String _readErrorMessage = '';

  @override
  void dispose() {
    NfcReaderService.cancelSession();
    super.dispose();
  }

  void _readCard() {
    if (_readStatus == ReadStatus.reading) return;

    if (!widget.nfcAvailable) {
      setState(() {
        _readStatus = ReadStatus.error;
        _readErrorMessage = 'NFC is not available on this device';
      });
      return;
    }

    setState(() {
      _readStatus = ReadStatus.reading;
      _readResult = null;
      _readErrorMessage = '';
    });

    NfcReaderService.readCard(
      onSuccess: (result) {
        if (mounted) {
          setState(() {
            _readStatus = ReadStatus.success;
            _readResult = result;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _readStatus = ReadStatus.error;
            _readErrorMessage = error;
          });
          // Reset error state after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && _readStatus == ReadStatus.error) {
              setState(() {
                _readStatus = ReadStatus.idle;
                _readErrorMessage = '';
              });
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // NFC availability warning
        if (!widget.nfcAvailable) const NfcAvailabilityWarning(),

        // Content area
        Expanded(
          child: _readResult != null
              ? _buildReadResult()
              : _buildReadInstructions(),
        ),

        // Status display
        _buildStatusDisplay(),

        // Read button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _readStatus != ReadStatus.reading ? _readCard : null,
              icon: Icon(
                _readStatus == ReadStatus.reading
                    ? Icons.hourglass_empty
                    : Icons.nfc,
              ),
              label: Text(
                _readStatus == ReadStatus.reading ? 'Reading...' : 'Read Card',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadInstructions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 80, color: colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              'Tap "Read Card" and hold your NFC card to the phone',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadResult() {
    if (_readResult == null) return const SizedBox.shrink();

    final result = _readResult!;
    final colorScheme = Theme.of(context).colorScheme;

    IconData cardIcon;
    String cardTypeLabel;
    String? specialFunctionName;
    // Use different ColorScheme colors for different card types
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    switch (result.cardType) {
      case CardTypeNfc.person:
        cardIcon = Icons.person;
        cardTypeLabel = 'Person Card';
        backgroundColor = colorScheme.primaryContainer;
        iconColor = colorScheme.primary;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case CardTypeNfc.specialFunction:
        // Try to get the display name for the special function
        specialFunctionName = SpecialCards.getDisplayName(result.text ?? '');
        final specialIcon = SpecialCards.getIcon(result.text ?? '');

        cardIcon = specialIcon ?? Icons.settings;
        cardTypeLabel = specialFunctionName ?? 'Special Function Card';
        backgroundColor = colorScheme.tertiaryContainer;
        iconColor = colorScheme.tertiary;
        textColor = colorScheme.onTertiaryContainer;
        break;
      case CardTypeNfc.empty:
        cardIcon = Icons.credit_card;
        cardTypeLabel = 'Empty Card';
        backgroundColor = colorScheme.surfaceContainerHighest;
        iconColor = colorScheme.onSurfaceVariant;
        textColor = colorScheme.onSurface;
        break;
      case CardTypeNfc.unknown:
        cardIcon = Icons.help_outline;
        cardTypeLabel = 'Unknown Card';
        backgroundColor = colorScheme.surfaceContainerHighest;
        iconColor = colorScheme.onSurfaceVariant;
        textColor = colorScheme.onSurface;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card type header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(cardIcon, size: 40, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardTypeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // For special functions with recognized names, show both the friendly name and raw value
                      if (specialFunctionName != null) ...[
                        Text(
                          specialFunctionName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.text ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ] else
                        Text(
                          result.text ?? '(empty)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Records section
          Text(
            'NDEF Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...result.allRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      record,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    switch (_readStatus) {
      case ReadStatus.idle:
        return NfcStatusBanner.info(
          _readResult == null
              ? 'Tap "Read Card" to scan an NFC card'
              : 'Card read successfully. Tap "Read Card" to scan another.',
        );
      case ReadStatus.reading:
        return NfcStatusBanner.inProgress('Hold your card near the phone...');
      case ReadStatus.success:
        return NfcStatusBanner.success('Card read successfully!');
      case ReadStatus.error:
        return NfcStatusBanner.error(
          _readErrorMessage.isEmpty
              ? 'Failed to read card. Please try again.'
              : _readErrorMessage,
        );
    }
  }
}

enum ReadStatus { idle, reading, success, error }
