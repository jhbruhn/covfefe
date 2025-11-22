import 'dart:async';
import 'dart:developer' as developer;
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../models/coffee_statistics.dart';
import '../models/statistic_type.dart';
import 'ble_statistics_service.dart';

/// Service to persist statistics to local database
/// Uses stream-based reactive architecture - listens to BLE statistics stream
/// and automatically saves snapshots when values change.
/// 
/// This service is the SINGLE SOURCE OF TRUTH for statistics data.
/// It provides a unified stream that combines:
/// - Persisted numeric statistics from database
/// - Live leaderboard data from BLE (pass-through)
/// - Live timestamps from BLE (pass-through)
class StatisticsPersistenceService {
  final StatisticsDatabase _database = StatisticsDatabase();
  final BleStatisticsService _bleService;
  
  StreamSubscription<CoffeeStatistics>? _bleSubscription;
  StreamSubscription<BleConnectionState>? _connectionSubscription;
  final _statisticsController = StreamController<CoffeeStatistics>.broadcast();
  
  Map<StatisticType, int> _latestValues = {};
  CoffeeStatistics? _lastKnownStatistics;
  
  /// Stream of statistics - the single source of truth for the UI
  /// Combines database-persisted values with live BLE data (leaderboards, timestamps)
  Stream<CoffeeStatistics> get statisticsStream => _statisticsController.stream;
  
  StatisticsPersistenceService(this._bleService) {
    _initialize();
  }
  
  /// Initialize the service
  Future<void> _initialize() async {
    // Load latest values from database
    await _loadLatestValues();
    
    // Start listening to BLE statistics stream
    _startListening();
  }
  
  /// Load latest values from database
  Future<void> _loadLatestValues() async {
    try {
      _latestValues = await getLatestValues();
      developer.log(
        'Loaded ${_latestValues.length} statistics from database',
        name: 'StatisticsPersistenceService',
      );
      
      // Emit cached statistics immediately
      if (_latestValues.isNotEmpty) {
        final cachedStatistics = CoffeeStatistics(
          totalConsumptions: _latestValues[StatisticType.totalCoffees] ?? 0,
          totalCleanings: _latestValues[StatisticType.totalCleanings] ?? 0,
          totalRefills: _latestValues[StatisticType.totalRefills] ?? 0,
          totalUsers: _latestValues[StatisticType.totalUsers] ?? 0,
          coffeesSinceCleaning: _latestValues[StatisticType.coffeesSinceCleaning] ?? 0,
          coffeesSinceRefill: _latestValues[StatisticType.coffeesSinceRefill] ?? 0,
          isCached: true,
        );
        _lastKnownStatistics = cachedStatistics;
        _statisticsController.add(cachedStatistics);
      }
    } catch (e) {
      developer.log(
        'Error loading latest values: $e',
        name: 'StatisticsPersistenceService',
      );
    }
  }
  
  /// Start listening to BLE statistics and connection streams
  void _startListening() {
    _bleSubscription = _bleService.statisticsStream.listen(
      (bleStatistics) {
        _handleBleStatisticsUpdate(bleStatistics);
      },
      onError: (error) {
        developer.log('Error in BLE statistics stream: $error', name: 'StatisticsPersistenceService');
      },
    );

    _connectionSubscription = _bleService.connectionStateStream.listen((state) {
      if (state == BleConnectionState.disconnected && _lastKnownStatistics != null) {
        // When disconnected, re-emit the last known statistics as cached
        // This ensures the UI visually indicates the data is no longer live
        final cachedStats = _lastKnownStatistics!.copyWith(isCached: true);
        _statisticsController.add(cachedStats);
      }
    });
  }
  
  /// Handle statistics update from BLE stream
  Future<void> _handleBleStatisticsUpdate(CoffeeStatistics bleStatistics) async {
    final now = DateTime.now();
    
    // Save numeric statistics if changed
    // We don't pass previous value anymore, _saveIfChanged checks _latestValues
    await _saveIfChanged(StatisticType.totalCoffees, bleStatistics.totalConsumptions, now);
    await _saveIfChanged(StatisticType.totalCleanings, bleStatistics.totalCleanings, now);
    await _saveIfChanged(StatisticType.totalRefills, bleStatistics.totalRefills, now);
    await _saveIfChanged(StatisticType.totalUsers, bleStatistics.totalUsers, now);
    await _saveIfChanged(StatisticType.coffeesSinceCleaning, bleStatistics.coffeesSinceCleaning, now);
    await _saveIfChanged(StatisticType.coffeesSinceRefill, bleStatistics.coffeesSinceRefill, now);
    
    // Emit enriched statistics to UI
    // Use database values for numeric stats (single source of truth)
    // Pass through leaderboards and timestamps from BLE
    final enrichedStatistics = CoffeeStatistics(
      totalConsumptions: _latestValues[StatisticType.totalCoffees] ?? bleStatistics.totalConsumptions,
      totalCleanings: _latestValues[StatisticType.totalCleanings] ?? bleStatistics.totalCleanings,
      totalRefills: _latestValues[StatisticType.totalRefills] ?? bleStatistics.totalRefills,
      totalUsers: _latestValues[StatisticType.totalUsers] ?? bleStatistics.totalUsers,
      coffeesSinceCleaning: _latestValues[StatisticType.coffeesSinceCleaning] ?? bleStatistics.coffeesSinceCleaning,
      coffeesSinceRefill: _latestValues[StatisticType.coffeesSinceRefill] ?? bleStatistics.coffeesSinceRefill,
      // Pass through leaderboards and timestamps from BLE (not persisted)
      lastCleaningTime: bleStatistics.lastCleaningTime,
      lastRefillTime: bleStatistics.lastRefillTime,
      consumptionLeaderboard: bleStatistics.consumptionLeaderboard,
      cleaningLeaderboard: bleStatistics.cleaningLeaderboard,
      isCached: false, // Live update
    );
    
    _lastKnownStatistics = enrichedStatistics;
    _statisticsController.add(enrichedStatistics);
  }
  
  /// Save a statistic snapshot if the value has changed
  Future<void> _saveIfChanged(
    StatisticType type,
    int currentValue,
    DateTime timestamp,
  ) async {
    // Check against latest known value
    final previousValue = _latestValues[type];
    
    // If value hasn't changed, skip
    // This check happens synchronously before any await, preventing race conditions
    if (previousValue != null && currentValue == previousValue) {
      return;
    }

    // Optimistically update latest values cache immediately
    // This ensures subsequent calls (even before DB insert finishes) see the new value
    _latestValues[type] = currentValue;

    try {
      await _database.insertSnapshot(
        StatisticsSnapshotsCompanion(
          statisticType: drift.Value(type.name),
          value: drift.Value(currentValue),
          timestamp: drift.Value(timestamp),
        ),
      );
      
      developer.log(
        'Saved ${type.displayName}: $currentValue',
        name: 'StatisticsPersistenceService',
      );
    } catch (e) {
      developer.log(
        'Error saving ${type.displayName}: $e',
        name: 'StatisticsPersistenceService',
      );
      // Optional: Revert _latestValues if DB insert fails?
      // For now, we keep the optimistic value to avoid retry loops or inconsistency
    }
  }
  
  /// Get historical data for a specific statistic type
  Future<List<StatisticsSnapshot>> getHistory(StatisticType type) {
    return _database.getSnapshotsForType(type.name);
  }
  
  /// Get the latest value for a specific statistic type
  Future<int?> getLatestValue(StatisticType type) async {
    final snapshot = await _database.getLatestSnapshotForType(type.name);
    return snapshot?.value;
  }
  
  /// Get all latest values as a map
  Future<Map<StatisticType, int>> getLatestValues() async {
    final snapshots = await _database.getLatestSnapshots();
    final values = <StatisticType, int>{};
    
    for (final type in StatisticType.values) {
      final snapshot = snapshots[type.name];
      if (snapshot != null) {
        values[type] = snapshot.value;
      }
    }
    
    return values;
  }
  
  /// Get historical data within a date range
  Future<List<StatisticsSnapshot>> getHistoryInRange(
    StatisticType type,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _database.getSnapshotsInRange(type.name, startDate, endDate);
  }
  
  /// Clean up old data (keeps most recent 1000 entries per type by default)
  Future<void> cleanupOldData({int keepCount = 1000}) {
    return _database.cleanupOldSnapshots(keepCount: keepCount);
  }
  
  /// Dispose of resources
  void dispose() {
    _bleSubscription?.cancel();
    _connectionSubscription?.cancel();
    _statisticsController.close();
    _database.close();
  }
}
