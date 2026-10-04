import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import 'app_config.dart';
import 'mock_backend.dart';

class BookingService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('bookings');

  Stream<List<Booking>> watchAll() {
    if (AppConfig.useMockData) return MockBackend.instance.watchBookings();
    return _col.snapshots().map(
        (s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Booking>> watchForVenue(String venueId) {
    if (AppConfig.useMockData) {
      return MockBackend.instance
          .watchBookings()
          .map((all) => all.where((b) => b.venueId == venueId).toList());
    }
    return _col
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Future<Booking> create(Booking b) async {
    if (AppConfig.useMockData) {
      return MockBackend.instance.upsertBooking(b);
    }
    await _col.doc(b.id).set(b.toMap());
    return b;
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    if (AppConfig.useMockData) {
      final existing = MockBackend.instance.bookingsSnapshot
          .firstWhere((b) => b.id == id);
      await MockBackend.instance.upsertBooking(existing.copyWith(status: status));
      return;
    }
    await _col.doc(id).update({'status': status.wire});
  }

  Future<void> delete(String id) async {
    if (AppConfig.useMockData) return MockBackend.instance.deleteBooking(id);
    await _col.doc(id).delete();
  }

  /// Compute which dates are unavailable for a given venue+units combination.
  /// Only `confirmed` or `pending` bookings block availability; cancelled ones
  /// are ignored.
  Set<DateTime> computeBlockedDates({
    required List<Booking> bookings,
    required String venueId,
    required Set<String> unitIds,
  }) {
    final blocked = <DateTime>{};
    for (final b in bookings) {
      if (b.venueId != venueId) continue;
      if (b.status == BookingStatus.cancelled) continue;
      final overlapsUnit = b.unitIds.any(unitIds.contains);
      if (!overlapsUnit) continue;
      for (final d in b.dates) {
        blocked.add(DateTime(d.year, d.month, d.day));
      }
    }
    return blocked;
  }
}
