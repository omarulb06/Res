// GENERATED STUB.
//
// Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Until then, initializeApp() will throw and the app will automatically
// fall back to in-memory mock data (see main.dart + AppConfig).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to regenerate this file.',
        );
    }
  }

  // ---- Replace the placeholders below with real values from firebase_options generation. ----

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyVGgSgnSVA7JrGZTgumFielKQ4DwGidg',
    appId: '1:482038244267:android:b4920c34278187c980e8ee',
    messagingSenderId: '482038244267',
    projectId: 'resapp-4e5b2',
    storageBucket: 'resapp-4e5b2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.venueReservation',
  );
}