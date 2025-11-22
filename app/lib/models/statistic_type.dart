import 'package:flutter/material.dart';

/// Types of statistics that can be tracked historically
enum StatisticType {
  totalCoffees,
  totalCleanings,
  totalRefills,
  totalUsers,
  coffeesSinceCleaning,
  coffeesSinceRefill;

  /// Get a human-readable display name for this statistic type
  String get displayName {
    switch (this) {
      case StatisticType.totalCoffees:
        return 'Total Coffees';
      case StatisticType.totalCleanings:
        return 'Total Cleanings';
      case StatisticType.totalRefills:
        return 'Total Refills';
      case StatisticType.totalUsers:
        return 'Total Users';
      case StatisticType.coffeesSinceCleaning:
        return 'Coffees Since Cleaning';
      case StatisticType.coffeesSinceRefill:
        return 'Coffees Since Refill';
    }
  }

  /// Get an appropriate icon for this statistic type
  IconData get icon {
    switch (this) {
      case StatisticType.totalCoffees:
        return Icons.coffee;
      case StatisticType.totalCleanings:
        return Icons.cleaning_services;
      case StatisticType.totalRefills:
        return Icons.water_drop;
      case StatisticType.totalUsers:
        return Icons.people;
      case StatisticType.coffeesSinceCleaning:
        return Icons.coffee;
      case StatisticType.coffeesSinceRefill:
        return Icons.water_drop;
    }
  }

  /// Get an appropriate color for this statistic type
  Color get color {
    switch (this) {
      case StatisticType.totalCoffees:
        return Colors.brown;
      case StatisticType.totalCleanings:
        return Colors.blue;
      case StatisticType.totalRefills:
        return Colors.cyan;
      case StatisticType.totalUsers:
        return Colors.purple;
      case StatisticType.coffeesSinceCleaning:
        return Colors.orange;
      case StatisticType.coffeesSinceRefill:
        return Colors.teal;
    }
  }
}
