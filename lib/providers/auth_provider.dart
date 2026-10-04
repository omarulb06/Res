import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  AppUser? _user;
  bool _loading = true;
  StreamSubscription<AppUser?>? _sub;

  AppUser? get user => _user;
  bool get isLoading => _loading;
  bool get isSignedIn => _user != null;

  void bootstrap() {
    _sub = _auth.watchCurrentUser().listen((u) {
      _user = u;
      _loading = false;
      notifyListeners();
    }, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _auth.signIn(email: email, password: password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.client,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _auth.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // Admin ops
  Future<void> changeUserRole(String uid, UserRole role) =>
      _auth.updateRole(uid, role);

  Future<void> setUserSuspended(String uid, bool suspended) =>
      _auth.setSuspended(uid, suspended);

  Stream<List<AppUser>> watchAllUsers() => _auth.watchAllUsers();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
