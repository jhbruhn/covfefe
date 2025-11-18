import 'package:flutter/material.dart';
import '../services/nfc_writer_service.dart';
import '../widgets/nfc_status_banner.dart';
import '../models/special_cards.dart';

/// Screen for writing NDEF Text Records to NFC cards
class WriteCardScreen extends StatefulWidget {
  final bool nfcAvailable;

  const WriteCardScreen({super.key, required this.nfcAvailable});

  @override
  State<WriteCardScreen> createState() => _WriteCardScreenState();
}

class _WriteCardScreenState extends State<WriteCardScreen> {
  final TextEditingController _textController = TextEditingController();
  WriteStatus _writeStatus = WriteStatus.idle;
  String _writeErrorMessage = '';

  @override
  void dispose() {
    NfcWriterService.cancelSession();
    _textController.dispose();
    super.dispose();
  }

  String get _selectedText => _textController.text;

  CardType get _selectedCardType {
    final text = _selectedText;
    if (text.isEmpty) return CardType.none;
    if (text.startsWith('@@') && text.endsWith('@@')) {
      return CardType.specialFunction;
    }
    return CardType.person;
  }

  bool get _canWrite {
    return _selectedText.isNotEmpty && _writeStatus != WriteStatus.writing;
  }

  void _writeToCard() {
    if (!_canWrite) return;

    if (!widget.nfcAvailable) {
      setState(() {
        _writeStatus = WriteStatus.error;
        _writeErrorMessage = 'NFC is not available on this device';
      });
      return;
    }

    setState(() {
      _writeStatus = WriteStatus.writing;
      _writeErrorMessage = '';
    });

    // Write NDEF Text Record with UTF-8 encoding:
    // - For Person cards: The person's name (e.g., "Alice")
    // - For Special Function cards: The special function identifier (e.g., "@@CLEAN@@")
    NfcWriterService.writeTextRecord(
      text: _selectedText,
      onSuccess: () {
        if (mounted) {
          setState(() {
            _writeStatus = WriteStatus.success;
          });
          // Reset after showing success
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _writeStatus = WriteStatus.idle;
                _textController.clear();
              });
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _writeStatus = WriteStatus.error;
            _writeErrorMessage = error;
          });
          // Reset error state after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && _writeStatus == WriteStatus.error) {
              setState(() {
                _writeStatus = WriteStatus.idle;
                _writeErrorMessage = '';
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
        Expanded(child: _buildContent()),

        // Status display
        _buildStatusDisplay(),

        // Write button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _canWrite ? _writeToCard : null,
              icon: Icon(
                _writeStatus == WriteStatus.writing
                    ? Icons.hourglass_empty
                    : Icons.nfc,
              ),
              label: Text(
                _writeStatus == WriteStatus.writing
                    ? 'Writing...'
                    : 'Write to Card',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Card Text',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The card will contain one NDEF Text record with this value',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Card Text',
              hintText: 'Enter person name',
              prefixIcon: Icon(
                _selectedCardType == CardType.specialFunction
                    ? Icons.settings
                    : Icons.person,
              ),
              helperText: _selectedCardType == CardType.specialFunction
                  ? 'Special function (starts and ends with @@)'
                  : 'Person name',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Select: Special Function Cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to fill in the text field with a special function value',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...SpecialCards.all.map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _textController.text = card.ndefValue;
                    });
                  },
                  icon: Icon(card.icon),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.displayName),
                      Text(
                        'Value: ${card.ndefValue}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    switch (_writeStatus) {
      case WriteStatus.idle:
        return NfcStatusBanner.info(
          _selectedText.isEmpty
              ? 'Select or enter text, then tap "Write to Card"'
              : 'Ready to write ${_selectedCardType == CardType.person ? 'Person' : 'Special Function'} card: "$_selectedText"',
        );
      case WriteStatus.writing:
        return NfcStatusBanner.inProgress('Hold your card near the phone...');
      case WriteStatus.success:
        return NfcStatusBanner.success('Card written successfully!');
      case WriteStatus.error:
        return NfcStatusBanner.error(
          _writeErrorMessage.isEmpty
              ? 'Failed to write card. Please try again.'
              : _writeErrorMessage,
        );
    }
  }
}

enum WriteStatus { idle, writing, success, error }

enum CardType { none, person, specialFunction }
