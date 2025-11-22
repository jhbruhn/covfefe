import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Table for storing historical statistics snapshots
class StatisticsSnapshots extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Type of statistic (stored as string enum name)
  TextColumn get statisticType => text()();
  
  /// Value of the statistic at this point in time
  IntColumn get value => integer()();
  
  /// Timestamp when this snapshot was recorded
  DateTimeColumn get timestamp => dateTime()();
}

/// Main database class for statistics persistence
@DriftDatabase(tables: [StatisticsSnapshots])
class StatisticsDatabase extends _$StatisticsDatabase {
  StatisticsDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Insert a new statistics snapshot
  Future<int> insertSnapshot(StatisticsSnapshotsCompanion snapshot) {
    return into(statisticsSnapshots).insert(snapshot);
  }

  /// Get all snapshots for a specific statistic type, ordered by timestamp (newest first)
  Future<List<StatisticsSnapshot>> getSnapshotsForType(String type) {
    return (select(statisticsSnapshots)
          ..where((tbl) => tbl.statisticType.equals(type))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .get();
  }

  /// Get the most recent snapshot for a specific statistic type
  Future<StatisticsSnapshot?> getLatestSnapshotForType(String type) async {
    final query = select(statisticsSnapshots)
      ..where((tbl) => tbl.statisticType.equals(type))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
      ..limit(1);
    
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  /// Get the most recent snapshots for all statistic types
  Future<Map<String, StatisticsSnapshot>> getLatestSnapshots() async {
    final snapshots = <String, StatisticsSnapshot>{};
    
    // Get distinct statistic types
    final types = await customSelect(
      'SELECT DISTINCT statistic_type FROM statistics_snapshots',
      readsFrom: {statisticsSnapshots},
    ).map((row) => row.read<String>('statistic_type')).get();
    
    // Get latest snapshot for each type
    for (final type in types) {
      final snapshot = await getLatestSnapshotForType(type);
      if (snapshot != null) {
        snapshots[type] = snapshot;
      }
    }
    
    return snapshots;
  }

  /// Get snapshots within a date range for a specific type
  Future<List<StatisticsSnapshot>> getSnapshotsInRange(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(statisticsSnapshots)
          ..where((tbl) =>
              tbl.statisticType.equals(type) &
              tbl.timestamp.isBiggerOrEqualValue(startDate) &
              tbl.timestamp.isSmallerOrEqualValue(endDate))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .get();
  }

  /// Delete old snapshots (optional cleanup)
  /// Keeps only the most recent [keepCount] snapshots for each type
  Future<void> cleanupOldSnapshots({int keepCount = 1000}) async {
    final types = await customSelect(
      'SELECT DISTINCT statistic_type FROM statistics_snapshots',
      readsFrom: {statisticsSnapshots},
    ).map((row) => row.read<String>('statistic_type')).get();
    
    for (final type in types) {
      // Get IDs to keep
      final toKeep = await (select(statisticsSnapshots)
            ..where((tbl) => tbl.statisticType.equals(type))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
            ..limit(keepCount))
          .map((row) => row.id)
          .get();
      
      // Delete others
      await (delete(statisticsSnapshots)
            ..where((tbl) =>
                tbl.statisticType.equals(type) & tbl.id.isNotIn(toKeep)))
          .go();
    }
  }
}

/// Open a connection to the database using drift_flutter
QueryExecutor _openConnection() {
  return driftDatabase(name: 'statistics');
}
