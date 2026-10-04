import '../models/venue.dart';
import '../services/venue_service.dart';
import 'package:flutter/foundation.dart';

class VenueProvider extends ChangeNotifier {
  final VenueService _svc = VenueService();

  Stream<List<Venue>> watchAll() => _svc.watchAll();
  Stream<List<Venue>> watchForOwner(String uid) => _svc.watchForOwner(uid);

  Future<void> save(Venue venue) async {
    await _svc.upsert(venue);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _svc.delete(id);
    notifyListeners();
  }

  Future<void> approve(String id, bool approved) async {
    await _svc.setApproval(id, approved);
    notifyListeners();
  }
}
