import 'dart:async';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/venue.dart';
import '../models/venue_unit.dart';

/// Simple in-memory backend used when Firebase isn't configured.
///
/// Exposes stream-based reads so UI code can treat it the same way as
/// Firestore snapshots.
class MockBackend {
  MockBackend._();
  static final MockBackend instance = MockBackend._();

  final List<AppUser> _users = [
    AppUser(
      uid: 'demo-admin',
      email: 'admin@demo.app',
      displayName: 'Alex Admin',
      role: UserRole.admin,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    AppUser(
      uid: 'demo-owner',
      email: 'owner@demo.app',
      displayName: 'Olivia Owner',
      role: UserRole.owner,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    AppUser(
      uid: 'demo-client',
      email: 'client@demo.app',
      displayName: 'Chris Client',
      role: UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  final List<Venue> _venues = [
    Venue(
      id: 'v1',
      ownerId: 'demo-owner',
      title: 'The Marigold Grand Hall',
      description:
          'Elegant hall with crystal chandeliers, premium catering kitchen, and valet parking. Perfect for weddings and corporate galas.',
      location: 'Downtown · 221 Oak Avenue',
      imageUrl:
          'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=1200',
      isPublic: true,
      isApprovedByAdmin: true,
      category: VenueCategory.mixed,
      units: const [
        VenueUnit(unitId: 'u1', name: 'Indoor Grand Hall', capacity: 220, pricePerDay: 850),
        VenueUnit(unitId: 'u2', name: 'Outdoor Garden Terrace', capacity: 350, pricePerDay: 600),
        VenueUnit(unitId: 'u3', name: 'VIP Lounge', capacity: 40, pricePerDay: 220),
      ],
    ),
    Venue(
      id: 'v2',
      ownerId: 'demo-owner',
      title: 'Skyline Rooftop',
      description:
          'Panoramic city views, modern bar, fire pits. Ideal for cocktail receptions and launch parties.',
      location: 'Midtown · 48 Horizon Blvd (floor 27)',
      imageUrl:
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200',
      isPublic: false,
      accessCode: '2468',
      isApprovedByAdmin: true,
      category: VenueCategory.outdoor,
      units: const [
        VenueUnit(unitId: 'u1', name: 'Full Rooftop', capacity: 180, pricePerDay: 1200),
      ],
    ),
    Venue(
      id: 'v3',
      ownerId: 'demo-owner',
      title: 'Lakeside Barn',
      description:
          'Rustic wooden barn by the lake. Includes string lights, bonfire pit, and tented backup area.',
      location: 'Lakeshore · 9 Willow Lane',
      imageUrl:
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200',
      isPublic: true,
      isApprovedByAdmin: false, // waiting on admin approval
      category: VenueCategory.outdoor,
      units: const [
        VenueUnit(unitId: 'u1', name: 'Main Barn', capacity: 140, pricePerDay: 500),
        VenueUnit(unitId: 'u2', name: 'Lakeside Lawn', capacity: 220, pricePerDay: 350),
      ],
    ),
  ];

  final List<Booking> _bookings = [
    Booking(
      id: 'b1',
      venueId: 'v1',
      unitIds: const ['u1'],
      dates: [
        DateTime.now().add(const Duration(days: 3)),
        DateTime.now().add(const Duration(days: 5)),
      ],
      clientName: 'Dana Smith',
      clientPhone: '+1 555 0101',
      clientEmail: 'dana@example.com',
      status: BookingStatus.confirmed,
      totalPrice: 1700,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Booking(
      id: 'b2',
      venueId: 'v1',
      unitIds: const ['u2'],
      dates: [DateTime.now().add(const Duration(days: 10))],
      clientName: 'Rafael Ortiz',
      clientPhone: '+1 555 0199',
      clientEmail: 'r.ortiz@example.com',
      status: BookingStatus.pending,
      totalPrice: 600,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final _usersCtrl = StreamController<List<AppUser>>.broadcast();
  final _venuesCtrl = StreamController<List<Venue>>.broadcast();
  final _bookingsCtrl = StreamController<List<Booking>>.broadcast();

  void _emitAll() {
    _usersCtrl.add(List.unmodifiable(_users));
    _venuesCtrl.add(List.unmodifiable(_venues));
    _bookingsCtrl.add(List.unmodifiable(_bookings));
  }

  Stream<List<AppUser>> watchUsers() {
    scheduleMicrotask(_emitAll);
    return _usersCtrl.stream;
  }

  Stream<List<Venue>> watchVenues() {
    scheduleMicrotask(_emitAll);
    return _venuesCtrl.stream;
  }

  Stream<List<Booking>> watchBookings() {
    scheduleMicrotask(_emitAll);
    return _bookingsCtrl.stream;
  }

  // ---- CRUD ---------------------------------------------------------------

  Future<AppUser> upsertUser(AppUser user) async {
    final idx = _users.indexWhere((u) => u.uid == user.uid);
    if (idx == -1) {
      _users.add(user);
    } else {
      _users[idx] = user;
    }
    _emitAll();
    return user;
  }

  Future<AppUser?> findUserByEmail(String email) async {
    try {
      return _users.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<Venue> upsertVenue(Venue v) async {
    final idx = _venues.indexWhere((x) => x.id == v.id);
    if (idx == -1) {
      _venues.add(v);
    } else {
      _venues[idx] = v;
    }
    _emitAll();
    return v;
  }

  Future<void> deleteVenue(String id) async {
    _venues.removeWhere((v) => v.id == id);
    _bookings.removeWhere((b) => b.venueId == id);
    _emitAll();
  }

  Future<Booking> upsertBooking(Booking b) async {
    final idx = _bookings.indexWhere((x) => x.id == b.id);
    if (idx == -1) {
      _bookings.add(b);
    } else {
      _bookings[idx] = b;
    }
    _emitAll();
    return b;
  }

  Future<void> deleteBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
    _emitAll();
  }

  List<AppUser> get usersSnapshot => List.unmodifiable(_users);
  List<Venue> get venuesSnapshot => List.unmodifiable(_venues);
  List<Booking> get bookingsSnapshot => List.unmodifiable(_bookings);
}
