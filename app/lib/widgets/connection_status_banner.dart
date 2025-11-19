import 'package:flutter/material.dart';
import '../services/ble_statistics_service.dart';

/// Banner widget to display BLE connection status
class ConnectionStatusBanner extends StatelessWidget {
  final BleConnectionState connectionState;
  final VoidCallback? onRetry;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (connectionState) {
      case BleConnectionState.connected:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        icon = Icons.bluetooth_connected;
        message = 'Connected to coffee reader';
        break;
      case BleConnectionState.connecting:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        icon = Icons.bluetooth_searching;
        message = 'Connecting...';
        break;
      case BleConnectionState.scanning:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        icon = Icons.bluetooth_searching;
        message = 'Scanning for device...';
        break;
      case BleConnectionState.disconnected:
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        icon = Icons.bluetooth_disabled;
        message = 'Disconnected';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (connectionState == BleConnectionState.disconnected && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: textColor),
              ),
            ),
        ],
      ),
    );
  }
}
