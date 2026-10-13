// File generated for Gas Monitor Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:android:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:web:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:web:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:ios:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:ios:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyC6LfZmdRC1WdkS0CuE-MKNcf-VvUg6W0w',
    appId: '1:610885807813:web:c30dc341c72c28e5ff4aac',
    messagingSenderId: '610885807813',
    projectId: 'gasmonitoringsystem-77db2',
    databaseURL: 'https://gasmonitoringsystem-77db2-default-rtdb.firebaseio.com',
    storageBucket: 'gasmonitoringsystem-77db2.firebasestorage.app',
  );
}
