import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'app_config.dart';
import 'mock_backend.dart';

/// Thin wrapper around FirebaseAuth + Firestore `users` collection.
/// In mock mode, acts as a tiny in-memory auth with pre-seeded demo accounts.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      FirebaseFirestore.instance.collection('users');

  AppUser? _mockCurrentUser;
  final _mockAuthCtrl = StreamController<AppUser?>.broadcast();

  Stream<AppUser?> watchCurrentUser() {
    if (AppConfig.useMockData) {
      scheduleMicrotask(() => _mockAuthCtrl.add(_mockCurrentUser));
      return _mockAuthCtrl.stream;
    }
    return _auth.authStateChanges().asyncMap((fb) async {
      if (fb == null) return null;
      final doc = await _usersCol.doc(fb.uid).get();
      if (!doc.exists) {
        // First login: create a baseline client doc.
        final created = AppUser(
          uid: fb.uid,
          email: fb.email ?? '',
          displayName: fb.displayName,
          role: UserRole.client,
          createdAt: DateTime.now(),
        );
        await _usersCol.doc(fb.uid).set(created.toMap());
        return created;
      }
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    if (AppConfig.useMockData) {
      final user = await MockBackend.instance.findUserByEmail(email);
      if (user == null) {
        throw AuthException('No demo account found for $email. Try admin@demo.app, owner@demo.app, or client@demo.app.');
      }
      _mockCurrentUser = user;
      _mockAuthCtrl.add(user);
      return user;
    }

    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _usersCol.doc(cred.user!.uid).get();
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.client,
  }) async {
    if (AppConfig.useMockData) {
      final existing = await MockBackend.instance.findUserByEmail(email);
      if (existing != null) {
        throw AuthException('An account with that email already exists.');
      }
      final newUser = AppUser(
        uid: 'mock-${DateTime.now().microsecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
      );
      await MockBackend.instance.upsertUser(newUser);
      _mockCurrentUser = newUser;
      _mockAuthCtrl.add(newUser);
      return newUser;
    }

    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(displayName);
    final created = AppUser(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );
    await _usersCol.doc(cred.user!.uid).set(created.toMap());
    return created;
  }

  /// Sign in with a Google account via the native account picker.
  ///
  /// On first sign-in, creates a corresponding `/users/{uid}` document with
  /// role=client. Subsequent sign-ins reuse the existing document (and its
  /// role, which may have been promoted to owner/admin by an admin).
  Future<AppUser> signInWithGoogle() async {
    if (AppConfig.useMockData) {
      // Fall back to a demo client in mock mode (no OAuth available offline).
      final demo = await MockBackend.instance.findUserByEmail('client@demo.app');
      _mockCurrentUser = demo;
      _mockAuthCtrl.add(demo);
      return demo!;
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw AuthException('Google sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);

    final doc = await _usersCol.doc(cred.user!.uid).get();
    if (!doc.exists) {
      final created = AppUser(
        uid: cred.user!.uid,
        email: cred.user!.email ?? googleUser.email,
        displayName: cred.user!.displayName ?? googleUser.displayName,
        role: UserRole.client,
        createdAt: DateTime.now(),
      );
      await _usersCol.doc(cred.user!.uid).set(created.toMap());
      return created;
    }
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<void> signOut() async {
    if (AppConfig.useMockData) {
      _mockCurrentUser = null;
      _mockAuthCtrl.add(null);
      return;
    }
    // Sign out of both Google (if used) and Firebase.
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _auth.signOut();
  }

  /// Admin-only: update another user's role.
  Future<void> updateRole(String uid, UserRole role) async {
    if (AppConfig.useMockData) {
      final user = MockBackend.instance.usersSnapshot
          .firstWhere((u) => u.uid == uid);
      await MockBackend.instance.upsertUser(user.copyWith(role: role));
      return;
    }
    await _usersCol.doc(uid).update({'role': role.wire});
  }

  Future<void> setSuspended(String uid, bool suspended) async {
    if (AppConfig.useMockData) {
      final user = MockBackend.instance.usersSnapshot
          .firstWhere((u) => u.uid == uid);
      await MockBackend.instance.upsertUser(user.copyWith(suspended: suspended));
      return;
    }
    await _usersCol.doc(uid).update({'suspended': suspended});
  }

  Stream<List<AppUser>> watchAllUsers() {
    if (AppConfig.useMockData) return MockBackend.instance.watchUsers();
    return _usersCol.snapshots().map((s) =>
        s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
