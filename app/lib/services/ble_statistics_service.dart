import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_constants.dart';
import '../models/coffee_statistics.dart';
import '../models/leaderboard_entry.dart';

/// Service for managing BLE connection and reading coffee statistics
class BleStatisticsService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _statisticsController = StreamController<CoffeeStatistics>.broadcast();
  
  String? _connectedDeviceId;
  CoffeeStatistics _currentStatistics = CoffeeStatistics.empty();
  
  /// Stream of connection state updates
  Stream<BleConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Stream of statistics updates
  Stream<CoffeeStatistics> get statisticsStream => _statisticsController.stream;
  
  /// Current connection state
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState => _connectionState;
  
  /// Check and request BLE permissions
  Future<bool> _checkPermissions() async {
    // Check if we need to request permissions
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    }
    
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Required for BLE on older Android versions
    ].request();
    
    // Check if all required permissions are granted
    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    
    if (!scanGranted || !connectGranted) {
      developer.log('BLE permissions denied', name: 'BleStatisticsService');
      return false;
    }
    
    return true;
  }
  
  /// Start scanning for the Covfefe device
  Future<void> startScanning() async {
    // Check permissions first
    final hasPermissions = await _checkPermissions();
    if (!hasPermissions) {
      _updateConnectionState(BleConnectionState.disconnected);
      return;
    }
    
    _updateConnectionState(BleConnectionState.scanning);
    
    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [BleConstants.serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        if (device.name == BleConstants.deviceName) {
          developer.log('Found device: ${device.name} (${device.id})', name: 'BleStatisticsService');
          stopScanning();
          connectToDevice(device.id);
        }
      },
      onError: (error) {
        developer.log('Scan error: $error', name: 'BleStatisticsService');
        _updateConnectionState(BleConnectionState.disconnected);
      },
    );
    
    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_connectionState == BleConnectionState.scanning) {
        stopScanning();
        _updateConnectionState(BleConnectionState.disconnected);
      }
    });
  }
  
  /// Stop scanning for devices
  void stopScanning() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }
  
  /// Connect to a specific device
  void connectToDevice(String deviceId) {
    _updateConnectionState(BleConnectionState.connecting);
    _connectedDeviceId = deviceId;
    
    _connectionSubscription?.cancel();
    _connectionSubscription = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    ).listen(
      (connectionState) async {
        developer.log('Connection state: ${connectionState.connectionState}', name: 'BleStatisticsService');
        
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _updateConnectionState(BleConnectionState.connected);
          await _readAllCharacteristics(deviceId);
          _subscribeToNotifications(deviceId);
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          _updateConnectionState(BleConnectionState.disconnected);
          _handleDisconnection();
        }
      },
      onError: (error) {
        developer.log('Connection error: $error', name: 'BleStatisticsService');
        _updateConnectionState(BleConnectionState.disconnected);
      },
    );
  }
  
  /// Disconnect from the current device
  void disconnect() {
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectedDeviceId = null;
    _updateConnectionState(BleConnectionState.disconnected);
  }
  
  /// Handle disconnection and attempt reconnection
  void _handleDisconnection() {
    _notificationSubscription?.cancel();
    
    // Attempt to reconnect after a delay
    if (_connectedDeviceId != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_connectionState == BleConnectionState.disconnected && _connectedDeviceId != null) {
          developer.log('Attempting to reconnect...', name: 'BleStatisticsService');
          connectToDevice(_connectedDeviceId!);
        }
      });
    }
  }
  
  /// Read all characteristics from the device
  Future<void> _readAllCharacteristics(String deviceId) async {
    try {
      // Read statistics
      final totalConsumptions = await _readUint32(deviceId, BleConstants.totalConsumptionsUuid);
      final totalCleanings = await _readUint32(deviceId, BleConstants.totalCleaningsUuid);
      final totalRefills = await _readUint32(deviceId, BleConstants.totalRefillsUuid);
      final coffeesSinceCleaning = await _readUint32(deviceId, BleConstants.coffeesSinceCleaningUuid);
      final coffeesSinceRefill = await _readUint32(deviceId, BleConstants.coffeesSinceRefillUuid);
      final totalUsers = await _readUint32(deviceId, BleConstants.totalUsersUuid);
      
      // Read timestamps
      final lastCleaningTime = await _readTimestamp(deviceId, BleConstants.lastCleaningTimeUuid);
      final lastRefillTime = await _readTimestamp(deviceId, BleConstants.lastRefillTimeUuid);
      
      // Read leaderboards
      final consumptionLeaderboard = await _readLeaderboard(deviceId, BleConstants.consumptionLeaderboardUuid);
      final cleaningLeaderboard = await _readLeaderboard(deviceId, BleConstants.cleaningLeaderboardUuid);
      
      // Update statistics
      _currentStatistics = CoffeeStatistics(
        totalConsumptions: totalConsumptions,
        totalCleanings: totalCleanings,
        totalRefills: totalRefills,
        coffeesSinceCleaning: coffeesSinceCleaning,
        coffeesSinceRefill: coffeesSinceRefill,
        totalUsers: totalUsers,
        lastCleaningTime: lastCleaningTime,
        lastRefillTime: lastRefillTime,
        consumptionLeaderboard: consumptionLeaderboard,
        cleaningLeaderboard: cleaningLeaderboard,
      );
      
      _statisticsController.add(_currentStatistics);
    } catch (e) {
      developer.log('Error reading characteristics: $e', name: 'BleStatisticsService');
    }
  }
  
  /// Subscribe to notifications for real-time updates
  void _subscribeToNotifications(String deviceId) {
    // Subscribe to all statistics characteristics that support notifications
    final characteristicsToSubscribe = [
      BleConstants.totalConsumptionsUuid,
      BleConstants.totalCleaningsUuid,
      BleConstants.totalRefillsUuid,
      BleConstants.coffeesSinceCleaningUuid,
      BleConstants.coffeesSinceRefillUuid,
      BleConstants.totalUsersUuid,
    ];
    
    for (final uuid in characteristicsToSubscribe) {
      final characteristic = QualifiedCharacteristic(
        serviceId: BleConstants.serviceUuid,
        characteristicId: uuid,
        deviceId: deviceId,
      );
      
      _ble.subscribeToCharacteristic(characteristic).listen(
        (data) {
          _handleNotification(uuid, data);
        },
        onError: (error) {
          developer.log('Notification error for $uuid: $error', name: 'BleStatisticsService');
        },
      );
    }
  }
  
  /// Handle incoming notifications
  void _handleNotification(Uuid characteristicUuid, List<int> data) {
    final value = _parseUint32(data);
    
    if (characteristicUuid == BleConstants.totalConsumptionsUuid) {
      _currentStatistics = _currentStatistics.copyWith(totalConsumptions: value);
    } else if (characteristicUuid == BleConstants.totalCleaningsUuid) {
      _currentStatistics = _currentStatistics.copyWith(totalCleanings: value);
    } else if (characteristicUuid == BleConstants.totalRefillsUuid) {
      _currentStatistics = _currentStatistics.copyWith(totalRefills: value);
    } else if (characteristicUuid == BleConstants.coffeesSinceCleaningUuid) {
      _currentStatistics = _currentStatistics.copyWith(coffeesSinceCleaning: value);
    } else if (characteristicUuid == BleConstants.coffeesSinceRefillUuid) {
      _currentStatistics = _currentStatistics.copyWith(coffeesSinceRefill: value);
    } else if (characteristicUuid == BleConstants.totalUsersUuid) {
      _currentStatistics = _currentStatistics.copyWith(totalUsers: value);
    }
    
    _statisticsController.add(_currentStatistics);
  }
  
  /// Read a uint32 characteristic
  Future<int> _readUint32(String deviceId, Uuid characteristicUuid) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: deviceId,
    );
    
    final data = await _ble.readCharacteristic(characteristic);
    return _parseUint32(data);
  }
  
  /// Read a timestamp characteristic
  Future<DateTime?> _readTimestamp(String deviceId, Uuid characteristicUuid) async {
    final value = await _readUint32(deviceId, characteristicUuid);
    if (value == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  
  /// Read and parse a leaderboard characteristic
  Future<List<LeaderboardEntry>> _readLeaderboard(String deviceId, Uuid characteristicUuid) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: deviceId,
    );
    
    final data = await _ble.readCharacteristic(characteristic);
    return _parseLeaderboard(data);
  }
  
  /// Parse uint32 from little-endian bytes
  int _parseUint32(List<int> data) {
    if (data.length < 4) return 0;
    final buffer = Uint8List.fromList(data).buffer;
    return ByteData.view(buffer).getUint32(0, Endian.little);
  }
  
  /// Parse leaderboard binary format
  /// Format: [count:4][karma:4][timestamp:4][name_len:1][name:name_len]
  List<LeaderboardEntry> _parseLeaderboard(List<int> data) {
    final entries = <LeaderboardEntry>[];
    int offset = 0;
    
    while (offset < data.length) {
      try {
        // Read count (4 bytes, little-endian uint32)
        if (offset + 4 > data.length) break;
        final buffer = Uint8List.fromList(data).buffer;
        final byteData = ByteData.view(buffer);
        final count = byteData.getUint32(offset, Endian.little);
        offset += 4;
        
        // Read karma (4 bytes, little-endian float)
        if (offset + 4 > data.length) break;
        final karma = byteData.getFloat32(offset, Endian.little);
        offset += 4;
        
        // Read timestamp (4 bytes, little-endian uint32)
        if (offset + 4 > data.length) break;
        final timestampSeconds = byteData.getUint32(offset, Endian.little);
        offset += 4;
        
        // Read name length (1 byte)
        if (offset >= data.length) break;
        final nameLen = data[offset];
        offset += 1;
        
        // Read name (nameLen bytes)
        if (offset + nameLen > data.length) break;
        final nameBytes = data.sublist(offset, offset + nameLen);
        final name = String.fromCharCodes(nameBytes);
        offset += nameLen;
        
        // Create timestamp (null if 0)
        final timestamp = timestampSeconds > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000)
            : null;
        
        entries.add(LeaderboardEntry(
          name: name,
          count: count,
          karma: karma,
          timestamp: timestamp,
        ));
      } catch (e) {
        developer.log('Error parsing leaderboard entry at offset $offset: $e', name: 'BleStatisticsService');
        break;
      }
    }
    
    return entries;
  }
  
  /// Update connection state and notify listeners
  void _updateConnectionState(BleConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  /// Dispose of resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _statisticsController.close();
  }
}

/// BLE connection states
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}
