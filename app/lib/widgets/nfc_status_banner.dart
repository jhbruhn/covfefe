import 'package:flutter/material.dart';

enum BannerType { info, inProgress, success, error, warning }

/// Reusable status banner widget for NFC operations
class NfcStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final BannerType type;
  final bool showSpinner;

  const NfcStatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.type,
    this.showSpinner = false,
  });

  /// Info/idle status banner
  factory NfcStatusBanner.info(String message) {
    return NfcStatusBanner(
      icon: Icons.info_outline,
      message: message,
      type: BannerType.info,
    );
  }

  /// Reading/writing in progress banner
  factory NfcStatusBanner.inProgress(String message) {
    return NfcStatusBanner(
      icon: Icons.nfc,
      message: message,
      type: BannerType.inProgress,
      showSpinner: true,
    );
  }

  /// Success banner
  factory NfcStatusBanner.success(String message) {
    return NfcStatusBanner(
      icon: Icons.check_circle,
      message: message,
      type: BannerType.success,
    );
  }

  /// Error banner
  factory NfcStatusBanner.error(String message) {
    return NfcStatusBanner(
      icon: Icons.error_outline,
      message: message,
      type: BannerType.error,
    );
  }

  /// Warning banner
  factory NfcStatusBanner.warning(String message) {
    return NfcStatusBanner(
      icon: Icons.warning,
      message: message,
      type: BannerType.warning,
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case BannerType.info:
        return colorScheme.primaryContainer;
      case BannerType.inProgress:
        return colorScheme.tertiaryContainer;
      case BannerType.success:
        return colorScheme.secondaryContainer;
      case BannerType.error:
        return colorScheme.errorContainer;
      case BannerType.warning:
        return colorScheme.tertiaryContainer;
    }
  }

  Color _getIconColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case BannerType.info:
        return colorScheme.primary;
      case BannerType.inProgress:
        return colorScheme.tertiary;
      case BannerType.success:
        return colorScheme.secondary;
      case BannerType.error:
        return colorScheme.error;
      case BannerType.warning:
        return colorScheme.tertiary;
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case BannerType.info:
        return colorScheme.onPrimaryContainer;
      case BannerType.inProgress:
        return colorScheme.onTertiaryContainer;
      case BannerType.success:
        return colorScheme.onSecondaryContainer;
      case BannerType.error:
        return colorScheme.onErrorContainer;
      case BannerType.warning:
        return colorScheme.onTertiaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getBackgroundColor(context),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getIconColor(context),
              ),
            )
          else
            Icon(icon, color: _getIconColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(context),
                fontWeight: showSpinner ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning banner for NFC availability
class NfcAvailabilityWarning extends StatelessWidget {
  const NfcAvailabilityWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return NfcStatusBanner.warning('NFC is not available on this device');
  }
}
