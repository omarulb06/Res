import 'venue_unit.dart';

enum VenueCategory { indoor, outdoor, mixed }

extension VenueCategoryX on VenueCategory {
  String get label => switch (this) {
        VenueCategory.indoor => 'Indoor',
        VenueCategory.outdoor => 'Outdoor',
        VenueCategory.mixed => 'Indoor + Outdoor',
      };

  String get wire => name;

  static VenueCategory parse(String? v) {
    switch (v) {
      case 'indoor':
        return VenueCategory.indoor;
      case 'outdoor':
        return VenueCategory.outdoor;
      default:
        return VenueCategory.mixed;
    }
  }
}

class Venue {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String location;
  final String imageUrl;
  final bool isPublic;
  final String? accessCode; // 4-6 digit PIN
  final bool isApprovedByAdmin;
  final VenueCategory category;
  final List<VenueUnit> units;

  const Venue({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.isPublic,
    required this.isApprovedByAdmin,
    required this.category,
    required this.units,
    this.accessCode,
  });

  int get maxCapacity =>
      units.fold<int>(0, (sum, u) => sum + u.capacity);

  double get minPricePerDay => units.isEmpty
      ? 0
      : units.map((u) => u.pricePerDay).reduce((a, b) => a < b ? a : b);

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
        'isPublic': isPublic,
        'accessCode': accessCode,
        'isApprovedByAdmin': isApprovedByAdmin,
        'category': category.wire,
        'units': units.map((u) => u.toMap()).toList(),
      };

  factory Venue.fromMap(String id, Map<String, dynamic> m) => Venue(
        id: id,
        ownerId: (m['ownerId'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        imageUrl: (m['imageUrl'] ?? '') as String,
        isPublic: (m['isPublic'] ?? true) as bool,
        accessCode: m['accessCode'] as String?,
        isApprovedByAdmin: (m['isApprovedByAdmin'] ?? false) as bool,
        category: VenueCategoryX.parse(m['category'] as String?),
        units: ((m['units'] as List?) ?? const [])
            .map((e) => VenueUnit.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Venue copyWith({
    String? title,
    String? description,
    String? location,
    String? imageUrl,
    bool? isPublic,
    String? accessCode,
    bool? isApprovedByAdmin,
    VenueCategory? category,
    List<VenueUnit>? units,
  }) =>
      Venue(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        imageUrl: imageUrl ?? this.imageUrl,
        isPublic: isPublic ?? this.isPublic,
        accessCode: accessCode ?? this.accessCode,
        isApprovedByAdmin: isApprovedByAdmin ?? this.isApprovedByAdmin,
        category: category ?? this.category,
        units: units ?? this.units,
      );
}
