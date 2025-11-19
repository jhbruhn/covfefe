import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coffee_statistics.dart';
import '../services/ble_statistics_service.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/statistic_card.dart';
import '../widgets/leaderboard_list_item.dart';

/// Statistics screen displaying coffee consumption data from BLE
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  final BleStatisticsService _bleService = BleStatisticsService();
  late TabController _tabController;
  
  CoffeeStatistics _statistics = CoffeeStatistics.empty();
  BleConnectionState _connectionState = BleConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to connection state changes
    _bleService.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });
    
    // Listen to statistics updates
    _bleService.statisticsStream.listen((statistics) {
      if (mounted) {
        setState(() {
          _statistics = statistics;
        });
      }
    });
    
    // Start scanning for device
    _connect();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bleService.dispose();
    super.dispose();
  }

  void _connect() async {
    await _bleService.startScanning();
  }

  Future<void> _refresh() async {
    _bleService.disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    _connect();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Connection status banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConnectionStatusBanner(
                  connectionState: _connectionState,
                  onRetry: _connect,
                ),
              ),
            ),

            // Loading or content
            if (_connectionState == BleConnectionState.connected)
              ..._buildConnectedContent(colorScheme)
            else
              _buildDisconnectedContent(colorScheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConnectedContent(ColorScheme colorScheme) {
    return [
      // Overall statistics section
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Overall Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
      // Statistics grid
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildListDelegate([
            StatisticCard(
              icon: Icons.coffee,
              label: 'Total Coffees',
              value: '${_statistics.totalConsumptions}',
              iconColor: Colors.brown,
            ),
            StatisticCard(
              icon: Icons.cleaning_services,
              label: 'Total Cleanings',
              value: '${_statistics.totalCleanings}',
              iconColor: Colors.blue,
            ),
            StatisticCard(
              icon: Icons.water_drop,
              label: 'Total Refills',
              value: '${_statistics.totalRefills}',
              iconColor: Colors.cyan,
            ),
            StatisticCard(
              icon: Icons.people,
              label: 'Total Users',
              value: '${_statistics.totalUsers}',
              iconColor: Colors.purple,
            ),
          ]),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      
      // Maintenance section
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Maintenance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.coffee, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Since Cleaning',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_statistics.coffeesSinceCleaning}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(_statistics.lastCleaningTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.water_drop, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Since Refill',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_statistics.coffeesSinceRefill}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(_statistics.lastRefillTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      
      // Leaderboards section
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Leaderboards',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
      // Tab bar
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Coffee Consumption'),
              Tab(text: 'Cleanings'),
            ],
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
      // Tab content
      SliverToBoxAdapter(
        child: SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardList(_statistics.consumptionLeaderboard),
              _buildLeaderboardList(_statistics.cleaningLeaderboard),
            ],
          ),
        ),
      ),
      
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildLeaderboardList(List leaderboard) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No data available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        return LeaderboardListItem(
          rank: index + 1,
          entry: leaderboard[index],
        );
      },
    );
  }

  Widget _buildDisconnectedContent(ColorScheme colorScheme) {
    String message;
    String? subtitle;
    IconData icon;
    
    if (_connectionState == BleConnectionState.scanning) {
      message = 'Scanning for coffee reader...';
      icon = Icons.bluetooth_searching;
    } else if (_connectionState == BleConnectionState.connecting) {
      message = 'Connecting to coffee reader...';
      icon = Icons.bluetooth_searching;
    } else {
      message = 'Not connected to coffee reader';
      subtitle = 'Make sure Bluetooth is enabled and permissions are granted';
      icon = Icons.bluetooth_disabled;
    }

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: colorScheme.outline),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_connectionState == BleConnectionState.disconnected) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Never';
    }
    return 'Last: ${DateFormat('MMM d, HH:mm').format(timestamp)}';
  }
}
