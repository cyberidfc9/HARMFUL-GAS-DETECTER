import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../models/device_state.dart';
import '../models/historical_record.dart';
import '../models/alert_item.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  FirebaseDatabase? _database;
  FirebaseAuth? _auth;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
      );
      _auth = FirebaseAuth.instance;

      // Attempt anonymous auth if not already signed in (satisfies security rules if set to auth != null)
      try {
        if (_auth?.currentUser == null) {
          await _auth?.signInAnonymously();
        }
      } catch (authError) {
        // If anonymous auth is disabled or not configured, continue gracefully
        debugPrint('Firebase anonymous auth notice: $authError');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  FirebaseDatabase? get database => _database;

  /// Monitors actual database connectivity (.info/connected)
  Stream<bool> get connectivityStream {
    if (_database == null) return Stream.value(false);
    return _database!.ref('.info/connected').onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    }).handleError((_) => false);
  }

  /// Live Stream of Device Current State
  /// Listens to the device path or fallback root
  Stream<DeviceState> streamDeviceState({required String deviceId, String? customPath}) {
    if (_database == null) {
      return Stream.value(DeviceState.empty(deviceId));
    }

    final String path = customPath?.isNotEmpty == true
        ? customPath!
        : 'devices/$deviceId/current';

    final controller = StreamController<DeviceState>.broadcast();

    // Primary listener
    final primaryRef = _database!.ref(path);
    late StreamSubscription<DatabaseEvent> sub;

    sub = primaryRef.onValue.listen(
      (event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final state = DeviceState.fromMap(deviceId, event.snapshot.value);
          controller.add(state);
        } else {
          // If primary path empty, check root device path: devices/$deviceId or just root
          _checkFallbackDevice(deviceId, controller);
        }
      },
      onError: (error) {
        debugPrint('Error reading live device state at $path: $error');
        controller.add(DeviceState.empty(deviceId));
      },
    );

    controller.onCancel = () {
      sub.cancel();
    };

    return controller.stream;
  }

  void _checkFallbackDevice(String deviceId, StreamController<DeviceState> controller) async {
    if (_database == null) {
      controller.add(DeviceState.empty(deviceId));
      return;
    }
    try {
      // Try 'devices/$deviceId'
      final fallback1 = await _database!.ref('devices/$deviceId').get();
      if (fallback1.exists && fallback1.value != null) {
        controller.add(DeviceState.fromMap(deviceId, fallback1.value));
        return;
      }

      // Try root 'current'
      final fallback2 = await _database!.ref('current').get();
      if (fallback2.exists && fallback2.value != null) {
        controller.add(DeviceState.fromMap(deviceId, fallback2.value));
        return;
      }

      // No data exists at all
      controller.add(DeviceState.empty(deviceId));
    } catch (e) {
      controller.add(DeviceState.empty(deviceId));
    }
  }

  /// Streams historical records with bounded queries
  Stream<List<HistoricalRecord>> streamHistory({
    required String deviceId,
    int limit = 200,
  }) {
    if (_database == null) {
      return Stream.value(<HistoricalRecord>[]);
    }

    final path = 'devices/$deviceId/history';
    final controller = StreamController<List<HistoricalRecord>>.broadcast();

    final query = _database!.ref(path).limitToLast(limit);
    final sub = query.onValue.listen(
      (event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          // Check fallback root 'history'
          _fetchFallbackHistory(limit, controller);
          return;
        }

        final records = _parseHistorySnapshot(event.snapshot);
        controller.add(records);
      },
      onError: (err) {
        debugPrint('Error streaming history from $path: $err');
        controller.add([]);
      },
    );

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  void _fetchFallbackHistory(int limit, StreamController<List<HistoricalRecord>> controller) async {
    if (_database == null) {
      controller.add([]);
      return;
    }
    try {
      final snap = await _database!.ref('history').limitToLast(limit).get();
      if (snap.exists && snap.value != null) {
        controller.add(_parseHistorySnapshot(snap));
      } else {
        controller.add([]);
      }
    } catch (_) {
      controller.add([]);
    }
  }

  List<HistoricalRecord> _parseHistorySnapshot(DataSnapshot snapshot) {
    final list = <HistoricalRecord>[];
    final dynamic val = snapshot.value;

    if (val is Map) {
      val.forEach((k, v) {
        list.add(HistoricalRecord.fromMap(k.toString(), v));
      });
    } else if (val is List) {
      for (int i = 0; i < val.length; i++) {
        if (val[i] != null) {
          list.add(HistoricalRecord.fromMap(i.toString(), val[i]));
        }
      }
    }

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  /// Streams genuine alerts produced by backend / ESP32 logic
  Stream<List<AlertItem>> streamAlerts({
    required String deviceId,
    int limit = 100,
  }) {
    if (_database == null) {
      return Stream.value(<AlertItem>[]);
    }

    final path = 'devices/$deviceId/alerts';
    final controller = StreamController<List<AlertItem>>.broadcast();

    final query = _database!.ref(path).limitToLast(limit);
    final sub = query.onValue.listen(
      (event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          _fetchFallbackAlerts(limit, controller);
          return;
        }

        final alerts = _parseAlertsSnapshot(event.snapshot);
        controller.add(alerts);
      },
      onError: (err) {
        debugPrint('Error streaming alerts: $err');
        controller.add([]);
      },
    );

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  void _fetchFallbackAlerts(int limit, StreamController<List<AlertItem>> controller) async {
    if (_database == null) {
      controller.add([]);
      return;
    }
    try {
      final snap = await _database!.ref('alerts').limitToLast(limit).get();
      if (snap.exists && snap.value != null) {
        controller.add(_parseAlertsSnapshot(snap));
      } else {
        controller.add([]);
      }
    } catch (_) {
      controller.add([]);
    }
  }

  List<AlertItem> _parseAlertsSnapshot(DataSnapshot snapshot) {
    final list = <AlertItem>[];
    final dynamic val = snapshot.value;

    if (val is Map) {
      val.forEach((k, v) {
        list.add(AlertItem.fromMap(k.toString(), v));
      });
    } else if (val is List) {
      for (int i = 0; i < val.length; i++) {
        if (val[i] != null) {
          list.add(AlertItem.fromMap(i.toString(), val[i]));
        }
      }
    }

    // Sort descending (latest alert first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
