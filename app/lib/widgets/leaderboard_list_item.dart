import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';

/// List item widget for displaying a leaderboard entry
class LeaderboardListItem extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool showKarma;

  const LeaderboardListItem({
    super.key,
    required this.rank,
    required this.entry,
    this.showKarma = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Medal colors for top 3
    Color? rankColor;
    IconData? medalIcon;
    if (rank == 1) {
      rankColor = Colors.amber[700];
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400];
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[400];
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (medalIcon != null)
                Icon(medalIcon, color: rankColor, size: 24)
              else
                Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.coffee, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${entry.count} ${entry.count == 1 ? 'coffee' : 'coffees'}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                if (showKarma) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.star, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Karma: ${entry.formattedKarma}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  entry.relativeTime,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
