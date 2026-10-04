import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum BookingStatus { pending, confirmed, cancelled }

extension BookingStatusX on BookingStatus {
  String get wire => name;
  String get label => switch (this) {
        BookingStatus.pending => 'Pending Payment',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.cancelled => 'Cancelled',
      };

  static BookingStatus parse(String? v) {
    switch (v) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}

final _dateFmt = DateFormat('yyyy-MM-dd');

class Booking {
  final String id;
  final String venueId;
  final List<String> unitIds;
  final List<DateTime> dates; // normalized to midnight
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final BookingStatus status;
  final double totalPrice;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.venueId,
    required this.unitIds,
    required this.dates,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
  });

  List<String> get dateStrings =>
      dates.map((d) => _dateFmt.format(d)).toList(growable: false);

  Map<String, dynamic> toMap() => {
        'id': id,
        'venueId': venueId,
        'unitIds': unitIds,
        'dates': dateStrings,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        'status': status.wire,
        'totalPrice': totalPrice,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Booking.fromMap(String id, Map<String, dynamic> m) {
    final rawDates = (m['dates'] as List?) ?? const [];
    final created = m['createdAt'];
    return Booking(
      id: id,
      venueId: (m['venueId'] ?? '') as String,
      unitIds: ((m['unitIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      dates: rawDates
          .map((e) => DateTime.parse(e.toString()))
          .toList(growable: false),
      clientName: (m['clientName'] ?? '') as String,
      clientPhone: (m['clientPhone'] ?? '') as String,
      clientEmail: (m['clientEmail'] ?? '') as String,
      status: BookingStatusX.parse(m['status'] as String?),
      totalPrice: (m['totalPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        venueId: venueId,
        unitIds: unitIds,
        dates: dates,
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        status: status ?? this.status,
        totalPrice: totalPrice,
        createdAt: createdAt,
      );
}
