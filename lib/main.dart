import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/firebase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase RTDB connection
  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase startup notice: $e');
  }

  runApp(
    const ProviderScope(
      child: GasMonitorApp(),
    ),
  );
}
