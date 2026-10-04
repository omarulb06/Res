class VenueUnit {
  final String unitId;
  final String name;
  final int capacity;
  final double pricePerDay;

  const VenueUnit({
    required this.unitId,
    required this.name,
    required this.capacity,
    required this.pricePerDay,
  });

  Map<String, dynamic> toMap() => {
        'unitId': unitId,
        'name': name,
        'capacity': capacity,
        'pricePerDay': pricePerDay,
      };

  factory VenueUnit.fromMap(Map<String, dynamic> m) => VenueUnit(
        unitId: (m['unitId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        capacity: (m['capacity'] ?? 0) as int,
        pricePerDay: (m['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      );

  VenueUnit copyWith({String? name, int? capacity, double? pricePerDay}) =>
      VenueUnit(
        unitId: unitId,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        pricePerDay: pricePerDay ?? this.pricePerDay,
      );
}
