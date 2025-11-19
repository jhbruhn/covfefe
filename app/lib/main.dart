import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/nfc_writer_service.dart';
import 'screens/write_card_screen.dart';
import 'screens/read_card_screen.dart';
import 'screens/statistics_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const CovfefeApp());
}

class CovfefeApp extends StatelessWidget {
  const CovfefeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covfefe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _cardManagementMode = 0; // 0 = Write, 1 = Read
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUIOverlay();
  }

  void _updateSystemUIOverlay() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  Future<void> _checkNfcAvailability() async {
    bool available = await NfcWriterService.isNfcAvailable();
    setState(() {
      _nfcAvailable = available;
    });
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Manage Cards' : 'Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedIndex == 0
          ? _buildCardManagementScreen()
          : _buildStatisticsScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.credit_card),
            label: 'Manage Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  Widget _buildCardManagementScreen() {
    return Column(
      children: [
        // Mode selector tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Write Card'),
                icon: Icon(Icons.edit),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Read Card'),
                icon: Icon(Icons.nfc),
              ),
            ],
            selected: {_cardManagementMode},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _cardManagementMode = newSelection.first;
              });
            },
          ),
        ),

        // Content area based on selected mode
        Expanded(
          child: _cardManagementMode == 0
              ? WriteCardScreen(nfcAvailable: _nfcAvailable)
              : ReadCardScreen(nfcAvailable: _nfcAvailable),
        ),
      ],
    );
  }

  Widget _buildStatisticsScreen() {
    return const StatisticsScreen();
  }
}
