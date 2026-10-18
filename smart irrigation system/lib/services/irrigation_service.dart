import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/irrigation_data.dart';

/// Service that interacts with Firebase Realtime Database for the Smart Irrigation system.
/// Connects to the Singapore region instance and manages the `/irrigation` node.
class IrrigationService {
  static const String databaseUrl =
      'https://smart-irrigation-system-4e066-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const String nodePath = 'irrigation';

  late final FirebaseDatabase _database;
  late final DatabaseReference _irrigationRef;
  late final DatabaseReference _connectedRef;

  IrrigationService() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    // Keep local cache synced for resilience
    _database.setPersistenceEnabled(true);
    _irrigationRef = _database.ref(nodePath);
    _connectedRef = _database.ref('.info/connected');
  }

  /// Realtime stream of irrigation data from `/irrigation`
  Stream<IrrigationData> get irrigationStream {
    return _irrigationRef.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final rawMap = event.snapshot.value;
        if (rawMap is Map) {
          return IrrigationData.fromMap(rawMap);
        }
      }
      return const IrrigationData();
    });
  }

  /// Stream of Firebase socket connection state
  Stream<bool> get connectionStream {
    return _connectedRef.onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }

  /// Write command to `/irrigation/command` ("auto", "pump_on", "pump_off")
  Future<void> sendCommand(String command) async {
    final validCommands = ['auto', 'pump_on', 'pump_off'];
    final normalized = command.toLowerCase().trim();
    if (!validCommands.contains(normalized)) {
      throw ArgumentError('Invalid command: $command. Must be auto, pump_on, or pump_off.');
    }

    try {
      await _irrigationRef.child('command').set(normalized).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out while sending command to Firebase.');
        },
      );
    } catch (e) {
      // Re-throw so caller can display snackbar/dialog
      rethrow;
    }
  }

  /// Fetch a single snapshot of data
  Future<IrrigationData> fetchCurrentData() async {
    final snapshot = await _irrigationRef.get();
    if (snapshot.exists && snapshot.value is Map) {
      return IrrigationData.fromMap(snapshot.value as Map);
    }
    return const IrrigationData();
  }
}
