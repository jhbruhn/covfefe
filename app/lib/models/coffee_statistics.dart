import 'leaderboard_entry.dart';

/// Holds all coffee statistics data from the BLE server
class CoffeeStatistics {
  // Overall statistics
  final int totalConsumptions;
  final int totalCleanings;
  final int totalRefills;
  final int coffeesSinceCleaning;
  final int coffeesSinceRefill;
  final int totalUsers;

  // Timestamps
  final DateTime? lastCleaningTime;
  final DateTime? lastRefillTime;

  // Leaderboards
  final List<LeaderboardEntry> consumptionLeaderboard;
  final List<LeaderboardEntry> cleaningLeaderboard;

  // Metadata
  final bool isCached;

  CoffeeStatistics({
    this.totalConsumptions = 0,
    this.totalCleanings = 0,
    this.totalRefills = 0,
    this.coffeesSinceCleaning = 0,
    this.coffeesSinceRefill = 0,
    this.totalUsers = 0,
    this.lastCleaningTime,
    this.lastRefillTime,
    this.consumptionLeaderboard = const [],
    this.cleaningLeaderboard = const [],
    this.isCached = false,
  });

  /// Create an empty statistics object
  factory CoffeeStatistics.empty() {
    return CoffeeStatistics();
  }

  /// Create a copy with updated values
  CoffeeStatistics copyWith({
    int? totalConsumptions,
    int? totalCleanings,
    int? totalRefills,
    int? coffeesSinceCleaning,
    int? coffeesSinceRefill,
    int? totalUsers,
    DateTime? lastCleaningTime,
    DateTime? lastRefillTime,
    List<LeaderboardEntry>? consumptionLeaderboard,
    List<LeaderboardEntry>? cleaningLeaderboard,
    bool? isCached,
  }) {
    return CoffeeStatistics(
      totalConsumptions: totalConsumptions ?? this.totalConsumptions,
      totalCleanings: totalCleanings ?? this.totalCleanings,
      totalRefills: totalRefills ?? this.totalRefills,
      coffeesSinceCleaning: coffeesSinceCleaning ?? this.coffeesSinceCleaning,
      coffeesSinceRefill: coffeesSinceRefill ?? this.coffeesSinceRefill,
      totalUsers: totalUsers ?? this.totalUsers,
      lastCleaningTime: lastCleaningTime ?? this.lastCleaningTime,
      lastRefillTime: lastRefillTime ?? this.lastRefillTime,
      consumptionLeaderboard: consumptionLeaderboard ?? this.consumptionLeaderboard,
      cleaningLeaderboard: cleaningLeaderboard ?? this.cleaningLeaderboard,
      isCached: isCached ?? this.isCached,
    );
  }

  @override
  String toString() {
    return 'CoffeeStatistics(totalConsumptions: $totalConsumptions, totalCleanings: $totalCleanings, totalUsers: $totalUsers)';
  }
}
