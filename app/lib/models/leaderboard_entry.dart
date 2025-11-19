import 'package:intl/intl.dart';

/// Represents a single entry in a leaderboard
class LeaderboardEntry {
  final String name;
  final int count;
  final double karma;
  final DateTime? timestamp;

  LeaderboardEntry({
    required this.name,
    required this.count,
    required this.karma,
    this.timestamp,
  });

  /// Format the timestamp for display
  String get formattedTimestamp {
    if (timestamp == null || timestamp!.millisecondsSinceEpoch == 0) {
      return 'Never';
    }
    return DateFormat('MMM d, yyyy HH:mm').format(timestamp!);
  }

  /// Format the timestamp as a relative time (e.g., "2 hours ago")
  String get relativeTime {
    if (timestamp == null || timestamp!.millisecondsSinceEpoch == 0) {
      return 'Never';
    }
    
    final now = DateTime.now();
    final difference = now.difference(timestamp!);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format karma score with one decimal place
  String get formattedKarma {
    return karma.toStringAsFixed(1);
  }

  @override
  String toString() {
    return 'LeaderboardEntry(name: $name, count: $count, karma: $karma, timestamp: $timestamp)';
  }
}
