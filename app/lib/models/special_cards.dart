import 'package:flutter/material.dart';

/// Represents a special function card with a predefined NDEF value
class SpecialCard {
  /// The NDEF Text record value (e.g., "@@CLEAN@@")
  final String ndefValue;
  final IconData icon;
  final String displayName;

  const SpecialCard(this.ndefValue, this.icon, this.displayName);
}

/// Pre-defined special function cards available in the app
class SpecialCards {
  static const List<SpecialCard> all = [
    SpecialCard('@@CLEAN@@', Icons.cleaning_services, 'Cleaning Card'),
    SpecialCard(
      '@@CONSUMPTIONREPORT@@',
      Icons.coffee,
      'Consumption Report Card',
    ),
    SpecialCard('@@CLEANINGREPORT@@', Icons.analytics, 'Cleaning Report Card'),
    SpecialCard('@@REFILL@@', Icons.shopping_bag, 'Coffee Refill Card'),
  ];

  /// Get the display name for a special function NDEF value
  /// Returns null if the value is not a recognized special function
  static String? getDisplayName(String ndefValue) {
    for (final card in all) {
      if (card.ndefValue == ndefValue) {
        return card.displayName;
      }
    }
    return null;
  }

  /// Get the icon for a special function NDEF value
  /// Returns null if the value is not a recognized special function
  static IconData? getIcon(String ndefValue) {
    for (final card in all) {
      if (card.ndefValue == ndefValue) {
        return card.icon;
      }
    }
    return null;
  }
}
