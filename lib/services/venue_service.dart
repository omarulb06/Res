import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venue.dart';
import 'app_config.dart';
import 'mock_backend.dart';

class VenueService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('venues');

  Stream<List<Venue>> watchAll() {
    if (AppConfig.useMockData) return MockBackend.instance.watchVenues();
    return _col.snapshots().map(
        (s) => s.docs.map((d) => Venue.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Venue>> watchForOwner(String ownerId) {
    if (AppConfig.useMockData) {
      return MockBackend.instance
          .watchVenues()
          .map((all) => all.where((v) => v.ownerId == ownerId).toList());
    }
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((s) => s.docs.map((d) => Venue.fromMap(d.id, d.data())).toList());
  }

  Future<Venue> upsert(Venue venue) async {
    if (AppConfig.useMockData) {
      return MockBackend.instance.upsertVenue(venue);
    }
    await _col.doc(venue.id).set(venue.toMap());
    return venue;
  }

  Future<void> delete(String id) async {
    if (AppConfig.useMockData) {
      return MockBackend.instance.deleteVenue(id);
    }
    await _col.doc(id).delete();
  }

  Future<void> setApproval(String id, bool approved) async {
    if (AppConfig.useMockData) {
      final existing = MockBackend.instance.venuesSnapshot
          .firstWhere((v) => v.id == id);
      await MockBackend.instance
          .upsertVenue(existing.copyWith(isApprovedByAdmin: approved));
      return;
    }
    await _col.doc(id).update({'isApprovedByAdmin': approved});
  }
}
