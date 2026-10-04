import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _svc = BookingService();

  BookingService get service => _svc;

  Stream<List<Booking>> watchAll() => _svc.watchAll();
  Stream<List<Booking>> watchForVenue(String venueId) =>
      _svc.watchForVenue(venueId);

  Future<void> create(Booking b) async {
    await _svc.create(b);
    notifyListeners();
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _svc.updateStatus(id, status);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _svc.delete(id);
    notifyListeners();
  }
}
