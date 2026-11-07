// lib/models/pg_model.dart

double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0.0;
    return double.tryParse(trimmed) ?? 0.0;
  }
  return 0.0;
}

int _safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed) ?? 0;
  }
  return 0;
}

bool _safeToBool(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  return true;
}

// ============================================================
// FIXED: Helper to parse images - handles both List<String>
// and List<Map> (for detail endpoint)
// ============================================================
List<String> _parseImages(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    // If the list contains Strings, use them directly
    if (value.isNotEmpty && value.first is String) {
      return value.map((e) => e.toString()).toList();
    }
    // If the list contains Maps (like from detail endpoint)
    if (value.isNotEmpty && value.first is Map) {
      return value.map((e) {
        if (e is Map) {
          return e['image_url']?.toString() ?? e['url']?.toString() ?? '';
        }
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    // Fallback: convert everything to string
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

/// An admin-managed offer on a PG. The API only returns offers that are live.
class PgOffer {
  final int id;
  final String title;
  final String description;
  final String headline;
  final String offerType;
  final double? offerValue;
  final String couponCode;
  final String terms;
  final String? validUntil;

  /// Price strike-through: show [originalPrice] crossed out and [offerPrice] as the new price.
  final bool hasPriceCut;
  final double? originalPrice;
  final double? offerPrice;
  final double? discountAmount;

  /// When the offer ends, on this device's clock. Worked out from the server's
  /// "seconds left" at the moment the data arrived, so a wrong phone clock
  /// cannot make an offer look live (or expired) by mistake. null = no end time.
  final DateTime? endsAt;

  const PgOffer({
    required this.id,
    required this.title,
    this.description = '',
    this.headline = 'OFFER',
    this.offerType = 'custom',
    this.offerValue,
    this.couponCode = '',
    this.terms = '',
    this.validUntil,
    this.hasPriceCut = false,
    this.originalPrice,
    this.offerPrice,
    this.discountAmount,
    this.endsAt,
  });

  factory PgOffer.fromJson(Map<String, dynamic> json) {
    final rawValue = json['offer_value'];
    final secondsLeft = json['seconds_left'];
    final hasCut = json['has_price_cut'] == true ||
        json['has_price_cut'] == 1 ||
        (json['offer_price'] != null && json['original_price'] != null);
    return PgOffer(
      id: _safeToInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      headline: (json['headline']?.toString().isNotEmpty ?? false)
          ? json['headline'].toString()
          : 'OFFER',
      offerType: json['offer_type']?.toString() ?? 'custom',
      offerValue: rawValue == null ? null : _safeToDouble(rawValue),
      couponCode: json['coupon_code']?.toString() ?? '',
      terms: json['terms']?.toString() ?? '',
      validUntil: (json['valid_until']?.toString().isNotEmpty ?? false)
          ? json['valid_until'].toString()
          : null,
      hasPriceCut: hasCut && json['offer_price'] != null,
      originalPrice: json['original_price'] == null
          ? null
          : _safeToDouble(json['original_price']),
      offerPrice:
          json['offer_price'] == null ? null : _safeToDouble(json['offer_price']),
      discountAmount: json['discount_amount'] == null
          ? null
          : _safeToDouble(json['discount_amount']),
      endsAt: secondsLeft == null
          ? null
          : DateTime.now().add(Duration(seconds: _safeToInt(secondsLeft))),
    );
  }

  bool get isExpired => endsAt != null && !endsAt!.isAfter(DateTime.now());

  /// Time left, or null when the offer has no end time.
  Duration? get timeLeft {
    if (endsAt == null) return null;
    final d = endsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  /// "2d 5h", "7h 12m" or "42m 10s" – the live counter text (without "left").
  String get countdownText {
    final d = timeLeft;
    if (d == null) return '';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
  }

  /// "Valid till 31 Dec 2026" or a generic label when there is no end date.
  String get validityLabel {
    final v = validUntil;
    if (v == null) return 'Limited-time offer';
    final d = DateTime.tryParse(v);
    if (d == null) return 'Limited-time offer';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Valid till ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class PgModel {
  final int id;
  final String name;
  final String location;
  final double rating;
  final int totalRooms;
  final int totalCapacity;
  final int totalOccupied;
  final double rent;
  final double securityFee;
  final int numberOfFloors;
  final bool isActive;
  final String? coverImage;
  final List<String> images;
  final List<String> amenityNames;
  final String statusText;
  final int occupancyPercentage;
  final List<FloorModel> floors;
  final List<ReviewModel> reviews;
  final List<PgOffer> offers;

  /// Vacant (completely empty) rooms as decided by the server: the live number,
  /// or the number an admin typed in when manual room counts are switched on.
  final int? vacantRooms;
  final bool roomsManual;

  PgModel({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.totalRooms,
    required this.totalCapacity,
    required this.totalOccupied,
    required this.rent,
    required this.securityFee,
    required this.numberOfFloors,
    required this.isActive,
    this.coverImage,
    this.images = const [],
    this.amenityNames = const [],
    this.statusText = 'Vacant',
    this.occupancyPercentage = 0,
    this.floors = const [],
    this.reviews = const [],
    this.offers = const [],
    this.vacantRooms,
    this.roomsManual = false,
  });

  /// Offers that have not run out. The server already hides ended offers; this
  /// also removes one the moment its countdown reaches zero while the screen is open.
  List<PgOffer> get liveOffers => offers.where((o) => !o.isExpired).toList();
  bool get hasOffer => liveOffers.isNotEmpty;
  PgOffer? get bestOffer => liveOffers.isNotEmpty ? liveOffers.first : null;

  /// Rent to show as the new price when the best offer cuts the price (else null).
  double? get offerRent {
    final o = bestOffer;
    return (o != null && o.hasPriceCut) ? o.offerPrice : null;
  }

  /// Vacant rooms to show visitors: manual / server value first, else counted from floors.
  int get displayVacantRooms => vacantRooms ?? emptyRoomsCount ?? 0;

  PgModel copyWith({
    int? totalRooms,
    int? totalCapacity,
    int? totalOccupied,
    String? coverImage,
    List<String>? images,
    List<String>? amenityNames,
    List<FloorModel>? floors,
    List<ReviewModel>? reviews,
    List<PgOffer>? offers,
    int? vacantRooms,
    bool? roomsManual,
  }) {
    return PgModel(
      id: id,
      name: name,
      location: location,
      rating: rating,
      totalRooms: totalRooms ?? this.totalRooms,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      totalOccupied: totalOccupied ?? this.totalOccupied,
      rent: rent,
      securityFee: securityFee,
      numberOfFloors: numberOfFloors,
      isActive: isActive,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      amenityNames: amenityNames ?? this.amenityNames,
      statusText: statusText,
      occupancyPercentage: occupancyPercentage,
      floors: floors ?? this.floors,
      reviews: reviews ?? this.reviews,
      offers: offers ?? this.offers,
      vacantRooms: vacantRooms ?? this.vacantRooms,
      roomsManual: roomsManual ?? this.roomsManual,
    );
  }

  /// Count of completely empty rooms (occupiedCount == 0).
  /// A room with even 1 tenant is NOT counted as available space.
  /// Returns null if floors data is not available.
  int? get emptyRoomsCount {
    if (floors.isEmpty) return null;
    int count = 0;
    for (final floor in floors) {
      for (final room in floor.rooms) {
        if (room.occupiedCount == 0) {
          count++;
        }
      }
    }
    return count;
  }

  factory PgModel.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // FIXED: Parse images using the helper
    // ============================================================
    final List<String> images = _parseImages(json['images']);

    // Parse amenity_names - same logic but simpler (they're always strings)
    final List<String> amenityNames = (json['amenity_names'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final List<FloorModel> floors = (json['floors'] as List?)
            ?.map((f) => FloorModel.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [];

    final List<ReviewModel> reviews = (json['reviews'] as List?)
            ?.map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    final List<PgOffer> offers = (json['offers'] as List?)
            ?.whereType<Map>()
            .map((o) => PgOffer.fromJson(Map<String, dynamic>.from(o)))
            .toList() ??
        [];

    // ============================================================
    // FIXED: Get cover image from images list if not provided
    // ============================================================
    String? coverImage = json['cover_image']?.toString();
    if ((coverImage == null || coverImage.isEmpty) && images.isNotEmpty) {
      coverImage = images.first;
    }

    return PgModel(
      id: _safeToInt(json['id']),
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      rating: _safeToDouble(json['overall_rating']),
      totalRooms: _safeToInt(json['total_rooms']),
      totalCapacity: _safeToInt(json['total_capacity']),
      totalOccupied: _safeToInt(json['total_occupied']),
      rent: _safeToDouble(json['rent']),
      securityFee: _safeToDouble(json['security_fee']),
      numberOfFloors: _safeToInt(json['number_of_floors']),
      isActive: _safeToBool(json['is_active']),
      coverImage: coverImage,
      images: images,
      amenityNames: amenityNames,
      statusText: json['status_text']?.toString() ?? 'Vacant',
      occupancyPercentage: _safeToInt(json['occupancy_percentage']),
      floors: floors,
      reviews: reviews,
      offers: offers,
      vacantRooms:
          json['vacant_rooms'] == null ? null : _safeToInt(json['vacant_rooms']),
      roomsManual: json['rooms_manual'] == true || json['rooms_manual'] == 1,
    );
  }
}

class FloorModel {
  final int id;
  final int floorNumber;
  final List<RoomModel> rooms;
  final int totalRooms;
  final int totalCapacity;
  final int totalOccupied;
  final int occupancyPercentage;

  FloorModel({
    required this.id,
    required this.floorNumber,
    this.rooms = const [],
    this.totalRooms = 0,
    this.totalCapacity = 0,
    this.totalOccupied = 0,
    this.occupancyPercentage = 0,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    final List<RoomModel> rooms = (json['rooms'] as List?)
            ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return FloorModel(
      id: _safeToInt(json['id']),
      floorNumber: _safeToInt(json['floor_number']),
      rooms: rooms,
      totalRooms: _safeToInt(json['total_rooms']),
      totalCapacity: _safeToInt(json['total_capacity']),
      totalOccupied: _safeToInt(json['total_occupied']),
      occupancyPercentage: _safeToInt(json['occupancy_percentage']),
    );
  }
}

class RoomModel {
  final int id;
  final String roomNumber;
  final int capacity;
  final int occupiedCount;
  final int availableSpots;
  final bool isFull;
  final double? rent;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.occupiedCount,
    required this.availableSpots,
    required this.isFull,
    this.rent,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: _safeToInt(json['id']),
      roomNumber: json['room_number']?.toString() ?? '',
      capacity: _safeToInt(json['capacity']),
      occupiedCount: _safeToInt(json['occupied_count']),
      availableSpots: _safeToInt(json['available_spots']),
      isFull: _safeToBool(json['is_full']),
      rent: json['rent'] == null ? null : _safeToDouble(json['rent']),
    );
  }
}

class ReviewModel {
  final String name;
  final String comment;
  final double rating;
  final String date;

  ReviewModel({
    required this.name,
    required this.comment,
    required this.rating,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      name: json['name']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      rating: _safeToDouble(json['rating']),
      date: json['date']?.toString() ?? '',
    );
  }
}