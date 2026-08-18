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
  });

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