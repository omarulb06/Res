import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/venue_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class VenueReservationApp extends StatelessWidget {
  final SettingsProvider settings;
  const VenueReservationApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Settings is created in main() so it can be awaited; expose it here
        // using ChangeNotifierProvider.value so widgets can watch it.
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Venue Reservation',
            debugShowCheckedModeBanner: false,

            // --- Theme ---
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,

            // --- Localization ---
            // flutter_localizations provides Material + Cupertino + Widgets
            // translations (buttons, dialogs, ...). RTL mirroring is handled
            // automatically by Flutter when `locale` is Hebrew or Arabic.
            locale: settings.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('he'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supported) {
              // If the user has an explicit choice (settings.locale), MaterialApp
              // uses it. This callback runs on first boot before any choice: pick
              // the device locale if we support it; otherwise fall back to EN.
              if (deviceLocale == null) return const Locale('en');
              for (final s in supported) {
                if (s.languageCode == deviceLocale.languageCode) return s;
              }
              return const Locale('en');
            },

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
