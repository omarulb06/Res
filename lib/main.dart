import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'services/app_config.dart';

/// Entry point. Initializes Firebase if configured; otherwise boots in
/// mock-data mode so the UI is usable immediately for demos and tests.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load user preferences (theme + locale) before first paint so we don't
  // flash the default theme/language on cold start.
  final settings = SettingsProvider();
  await settings.init();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AppConfig.useMockData = false;
    if (kDebugMode) debugPrint('[boot] Firebase initialized -> using Cloud Firestore');
  } catch (e) {
    AppConfig.useMockData = true;
    if (kDebugMode) {
      debugPrint('[boot] Firebase init failed -> running with in-memory mock data. ($e)');
    }
  }

  runApp(VenueReservationApp(settings: settings));
}
