import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/app_config.dart';
import 'admin/admin_dashboard_screen.dart';
import 'client/discover_screen.dart';
import 'owner/owner_dashboard_screen.dart';

/// Routes based on current auth state + role.
///
/// Guests (unauthenticated) land on the client discovery screen so they can
/// browse public venues immediately. Owners and admins land on their
/// respective dashboards.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppConfig.useMockData
                    ? 'Starting in demo mode…'
                    : 'Connecting to Firestore…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user;
    if (user == null) {
      return const DiscoverScreen();
    }
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.owner:
        return const OwnerDashboardScreen();
      case UserRole.client:
        return const DiscoverScreen();
    }
  }
}
