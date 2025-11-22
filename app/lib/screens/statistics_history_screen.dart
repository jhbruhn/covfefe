import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/statistic_type.dart';
import '../services/statistics_persistence_service.dart';

/// Screen to display historical data for a specific statistic
class StatisticsHistoryScreen extends StatefulWidget {
  final StatisticType statisticType;
  final StatisticsPersistenceService persistenceService;

  const StatisticsHistoryScreen({
    super.key,
    required this.statisticType,
    required this.persistenceService,
  });

  @override
  State<StatisticsHistoryScreen> createState() => _StatisticsHistoryScreenState();
}

class _StatisticsHistoryScreenState extends State<StatisticsHistoryScreen> {
  List<StatisticsSnapshot> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final history = await widget.persistenceService.getHistory(widget.statisticType);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.statisticType.displayName} History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildHistoryTable(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.statisticType.icon,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No historical data yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data will appear here once statistics are collected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(ColorScheme colorScheme) {
    return Column(
      children: [
        // Summary card at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Entries',
                    '${_history.length}',
                    Icons.list,
                    colorScheme,
                  ),
                  _buildSummaryItem(
                    'Current Value',
                    '${_history.first.value}',
                    widget.statisticType.icon,
                    colorScheme,
                  ),
                  if (_history.length > 1)
                    _buildSummaryItem(
                      'First Value',
                      '${_history.last.value}',
                      Icons.history,
                      colorScheme,
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Date & Time',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Value',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text(
                  'Change',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // History list
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final snapshot = _history[index];
              final previousValue = index < _history.length - 1
                  ? _history[index + 1].value
                  : null;
              final change = previousValue != null
                  ? snapshot.value - previousValue
                  : null;
              
              return _buildHistoryRow(
                snapshot,
                change,
                colorScheme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Icon(icon, color: widget.statisticType.color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(
    StatisticsSnapshot snapshot,
    int? change,
    ColorScheme colorScheme,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    
    return InkWell(
      onTap: () {
        // Could show more details in a dialog if needed
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(snapshot.timestamp),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    timeFormat.format(snapshot.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${snapshot.value}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: change != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: change > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${change.abs()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: change > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
