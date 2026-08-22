// lib/models/auth_models.dart
import 'dart:convert';
import 'dart:typed_data';

// ============================================================
// USER MODEL
// ============================================================
class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String nationality;
  final String countryCode;
  final String phone;
  final String gender;
  final String role;
  final bool isActive;
  final String? createdAt;

  // Tenant specific fields
  final int? pgId;
  final int? roomId;
  final String? residency;
  final String? pgName;
  final String? roomNumber;
  final double? rent;
  final double? securityFee;
  final int? paymentDate;
  final String? paidFrom;
  final String? paidTill;
  final String? arrivalDate;
  final String? aadhaarId;
  final String? fatherAadhaarId;
  final String? cFormNumber;
  final String? efrroFrom;
  final String? efrroTill;
  final String? documentUrl;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.nationality,
    required this.countryCode,
    required this.phone,
    required this.gender,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.pgId,
    this.roomId,
    this.residency,
    this.pgName,
    this.roomNumber,
    this.rent,
    this.securityFee,
    this.paymentDate,
    this.paidFrom,
    this.paidTill,
    this.arrivalDate,
    this.aadhaarId,
    this.fatherAadhaarId,
    this.cFormNumber,
    this.efrroFrom,
    this.efrroTill,
    this.documentUrl,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final parsed = double.tryParse(trimmed);
      return parsed;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  static bool _parseIsActive(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return true;
  }

  static String _parseRole(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.toLowerCase().trim();
    return value.toString().toLowerCase().trim();
  }

  static String _extractRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      
      final payload = parts[1];
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> jsonData = jsonDecode(decoded);
      
      final role = jsonData['role']?.toString().toLowerCase() ?? '';
      return role;
    } catch (e) {
      return '';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    String roleValue = _parseRole(json['role']);
    
    if (roleValue.isEmpty && token != null && token.isNotEmpty) {
      roleValue = _extractRoleFromToken(token);
    }
    
    if (roleValue.isEmpty) {
    }
    

    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      nationality: json['nationality'] ?? '',
      countryCode: json['country_code'] ?? json['countryCode'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      role: roleValue,
      isActive: _parseIsActive(json['is_active'] ?? json['isActive']),
      createdAt: json['created_at'],
      
      pgId: _parseInt(json['pg_id']),
      roomId: _parseInt(json['room_id']),
      residency: json['residency'],
      pgName: json['pg_name'],
      roomNumber: json['room_number'],
      rent: _parseDouble(json['rent']),
      securityFee: _parseDouble(json['security_fee']),
      paymentDate: _parseInt(json['payment_date']),
      paidFrom: json['paid_from'],
      paidTill: json['paid_till'],
      arrivalDate: json['arrival_date'],
      aadhaarId: json['aadhaar_id'],
      fatherAadhaarId: json['father_aadhaar_id'],
      cFormNumber: json['c_form_number'],
      efrroFrom: json['efrro_from'],
      efrroTill: json['efrro_till'],
      documentUrl: json['document_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'nationality': nationality,
      'country_code': countryCode,
      'phone': phone,
      'gender': gender,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

// ============================================================
// LOGIN RESPONSE
// ============================================================
class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final bool mustChangePassword;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.mustChangePassword = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {

    UserModel? user;
    final String? token = json['token'];
    
    if (json['user'] != null) {
      try {
        final userData = json['user'] as Map<String, dynamic>;
        user = UserModel.fromJson(userData, token: token);
      } catch (e) {
        try {
          final userData = json['user'] as Map<String, dynamic>;
          String roleFromToken = '';
          if (token != null && token.isNotEmpty) {
            try {
              final parts = token.split('.');
              if (parts.length == 3) {
                String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
                while (normalized.length % 4 != 0) {
                  normalized += '=';
                }
                final decoded = utf8.decode(base64Url.decode(normalized));
                final Map<String, dynamic> jwtData = jsonDecode(decoded);
                roleFromToken = jwtData['role']?.toString().toLowerCase() ?? '';
              }
            } catch (_) {}
          }
          
          user = UserModel(
            id: userData['id'] ?? 0,
            fullName: userData['full_name'] ?? userData['fullName'] ?? '',
            email: userData['email'] ?? '',
            nationality: userData['nationality'] ?? '',
            countryCode: userData['country_code'] ?? userData['countryCode'] ?? '',
            phone: userData['phone'] ?? '',
            gender: userData['gender'] ?? '',
            role: roleFromToken,
            isActive: userData['is_active'] ?? userData['isActive'] ?? true,
            createdAt: userData['created_at'],
          );
        } catch (e2) {
        }
      }
    }

    bool mustChangePassword = false;
    if (json['must_change_password'] != null) {
      if (json['must_change_password'] is bool) {
        mustChangePassword = json['must_change_password'] as bool;
      } else if (json['must_change_password'] is int) {
        mustChangePassword = json['must_change_password'] == 1;
      } else if (json['must_change_password'] is String) {
        mustChangePassword = json['must_change_password'].toLowerCase() == 'true';
      }
    }

    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: token,
      user: user,
      mustChangePassword: mustChangePassword,
    );
  }
}

// ============================================================
// OTP RESPONSE
// ============================================================
class OtpResponse {
  final bool success;
  final String message;
  final String? resetToken;

  OtpResponse({
    required this.success,
    required this.message,
    this.resetToken,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resetToken: json['resetToken'],
    );
  }
}

// ============================================================
// GUEST MODEL
// ============================================================
class GuestModel {
  final String fullName;
  final String email;
  final String nationality;
  final String phone;

  GuestModel({
    required this.fullName,
    required this.email,
    required this.nationality,
    required this.phone,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      nationality: json['nationality'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'nationality': nationality,
      'phone': phone,
    };
  }

  GuestModel copyWith({
    String? fullName,
    String? email,
    String? nationality,
    String? phone,
  }) {
    return GuestModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      nationality: nationality ?? this.nationality,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'GuestModel(fullName: $fullName, email: $email, nationality: $nationality, phone: $phone)';
  }
}

// ============================================================
// NOTIFICATION MODEL
// ============================================================
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final int? entityId;
  final String? entityType;
  final String? link;
  final String? icon;
  final String? color;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.entityId,
    this.entityType,
    this.link,
    this.icon,
    this.color,
  });

  static int _parseInt(dynamic value) {
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      createdAt: _parseDateTime(json['created_at']),
      isRead: _parseBool(json['is_read']),
      entityId: _parseInt(json['entity_id']),
      entityType: json['entity_type'],
      link: json['link'],
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'entity_id': entityId,
      'entity_type': entityType,
      'link': link,
      'icon': icon,
      'color': color,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    int? entityId,
    String? entityType,
    String? link,
    String? icon,
    String? color,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      link: link ?? this.link,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, isRead: $isRead)';
  }
}

// ============================================================
// BILL MODEL - SINGLE DEFINITION
// ============================================================
class BillModel {
  final int id;
  final int tenantId;
  final double rentAmount;
  final double electricityAmount;
  final double maintenanceAmount;
  final double otherCharges;
  final double totalAmount;
  final double paidAmount;
  final double fineAmount;
  final String status;
  final String? paymentQr;
  final String? partialPaymentQr;
  final String? adminQr;
  final String? electricityMeterImage;
  final DateTime sentAt;
  final DateTime validUntil;
  final String? tenantName;
  final String? tenantEmail;
  final String? tenantPhone;
  final String? pgName;
  final String? roomNumber;
  final double dueAmount;
  final bool isOverdue;

  BillModel({
    required this.id,
    required this.tenantId,
    required this.rentAmount,
    required this.electricityAmount,
    required this.maintenanceAmount,
    required this.otherCharges,
    required this.totalAmount,
    required this.paidAmount,
    required this.fineAmount,
    required this.status,
    this.paymentQr,
    this.partialPaymentQr,
    this.adminQr,
    this.electricityMeterImage,
    required this.sentAt,
    required this.validUntil,
    this.tenantName,
    this.tenantEmail,
    this.tenantPhone,
    this.pgName,
    this.roomNumber,
    this.dueAmount = 0,
    this.isOverdue = false,
  });

  static double _parseDouble(dynamic value) {
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

  static int _parseInt(dynamic value) {
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: _parseInt(json['id']),
      tenantId: _parseInt(json['tenant_id']),
      rentAmount: _parseDouble(json['rent_amount']),
      electricityAmount: _parseDouble(json['electricity_amount']),
      maintenanceAmount: _parseDouble(json['maintenance_amount']),
      otherCharges: _parseDouble(json['other_charges']),
      totalAmount: _parseDouble(json['total_amount']),
      paidAmount: _parseDouble(json['paid_amount']),
      fineAmount: _parseDouble(json['fine_amount']),
      status: json['status'] ?? 'unpaid',
      paymentQr: json['payment_qr'],
      partialPaymentQr: json['partial_payment_qr'],
      adminQr: json['admin_qr'],
      electricityMeterImage: json['electricity_meter_image'],
      sentAt: _parseDateTime(json['sent_at']),
      validUntil: _parseDateTime(json['valid_until']),
      tenantName: json['tenant_name'],
      tenantEmail: json['tenant_email'],
      tenantPhone: json['tenant_phone'],
      pgName: json['pg_name'],
      roomNumber: json['room_number'],
      dueAmount: _parseDouble(json['due_amount']),
      isOverdue: json['is_overdue'] ?? false,
    );
  }
}

// ============================================================
// PAYMENT RECORD - SINGLE DEFINITION
// ============================================================
class PaymentRecord {
  final int id;
  final int billId;
  final double amount;
  final String paymentMethod;
  final String? transactionId;
  final String status;
  final DateTime createdAt;
  final String? type;
  final double? billTotal;
  final String? adminNotes;

  PaymentRecord({
    required this.id,
    required this.billId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.status,
    required this.createdAt,
    this.type,
    this.billTotal,
    this.adminNotes,
  });

  static double _parseDouble(dynamic value) {
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

  static int _parseInt(dynamic value) {
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    double amount = _parseDouble(json['amount']);
    if (amount == 0.0) {
      amount = _parseDouble(json['amount_paid']);
    }
    if (amount == 0.0) {
      amount = _parseDouble(json['paid_amount']);
    }
    
    return PaymentRecord(
      id: _parseInt(json['id']),
      billId: _parseInt(json['bill_id']),
      amount: amount,
      paymentMethod: json['payment_method'] ?? json['_gateway'] ?? 'online',
      transactionId: json['transaction_id'],
      status: json['status'] ?? 'pending',
      createdAt: _parseDateTime(json['created_at'] ?? json['payment_date']),
      type: json['_type'],
      billTotal: _parseDouble(json['bill_total']),
      adminNotes: json['admin_notes'] ?? json['notes'],
    );
  }
}

// ============================================================
// PAYMENT HISTORY - SINGLE DEFINITION
// ============================================================
class PaymentHistory {
  final UserModel? tenant;
  final List<PaymentRecord> onlinePayments;
  final List<PaymentRecord> cashPayments;
  final List<PaymentRecord> paymentProofs;

  PaymentHistory({
    this.tenant,
    this.onlinePayments = const [],
    this.cashPayments = const [],
    this.paymentProofs = const [],
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      tenant: json['tenant'] != null ? UserModel.fromJson(json['tenant']) : null,
      onlinePayments: json['online_payments'] is List
          ? (json['online_payments'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
      cashPayments: json['cash_payments'] is List
          ? (json['cash_payments'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
      paymentProofs: json['payment_proofs'] is List
          ? (json['payment_proofs'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
    );
  }
}

// ============================================================
// PGMODEL - SINGLE DEFINITION WITH SAFE PARSING
// ============================================================
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

  // ============================================================
  // SAFE STATIC PARSING METHODS - NO .toDouble() CALLS ON STRINGS
  // ============================================================
  
  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0.0;
      final parsed = double.tryParse(trimmed);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      final parsed = int.tryParse(trimmed);
      return parsed ?? 0;
    }
    return 0;
  }

  static bool _safeToBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return true;
  }

  static String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _safeToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<FloorModel> _safeToFloorList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e is Map<String, dynamic>)
          .map((e) => FloorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<ReviewModel> _safeToReviewList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e is Map<String, dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ============================================================
  // FACTORY: fromJson with safe parsing for ALL fields
  // ============================================================
  factory PgModel.fromJson(Map<String, dynamic> json) {
    return PgModel(
      id: _safeToInt(json['id']),
      name: _safeToString(json['name']),
      location: _safeToString(json['location']),
      rating: _safeToDouble(json['overall_rating']),
      totalRooms: _safeToInt(json['total_rooms']),
      totalCapacity: _safeToInt(json['total_capacity']),
      totalOccupied: _safeToInt(json['total_occupied']),
      rent: _safeToDouble(json['rent']),
      securityFee: _safeToDouble(json['security_fee']),
      numberOfFloors: _safeToInt(json['number_of_floors']),
      isActive: _safeToBool(json['is_active']),
      coverImage: _safeToString(json['cover_image']),
      images: _safeToStringList(json['images']),
      amenityNames: _safeToStringList(json['amenity_names']),
      statusText: _safeToString(json['status_text']),
      occupancyPercentage: _safeToInt(json['occupancy_percentage']),
      floors: _safeToFloorList(json['floors']),
      reviews: _safeToReviewList(json['reviews']),
    );
  }
}

// ============================================================
// FLOORMODEL - Safe parsing
// ============================================================
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

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      final parsed = int.tryParse(trimmed);
      return parsed ?? 0;
    }
    return 0;
  }

  static List<RoomModel> _safeToRoomList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e is Map<String, dynamic>)
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: _safeToInt(json['id']),
      floorNumber: _safeToInt(json['floor_number']),
      rooms: _safeToRoomList(json['rooms']),
      totalRooms: _safeToInt(json['total_rooms']),
      totalCapacity: _safeToInt(json['total_capacity']),
      totalOccupied: _safeToInt(json['total_occupied']),
      occupancyPercentage: _safeToInt(json['occupancy_percentage']),
    );
  }
}

// ============================================================
// ROOMMODEL - Safe parsing
// ============================================================
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

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      final parsed = int.tryParse(trimmed);
      return parsed ?? 0;
    }
    return 0;
  }

  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final parsed = double.tryParse(trimmed);
      return parsed;
    }
    return null;
  }

  static bool _safeToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: _safeToInt(json['id']),
      roomNumber: _safeToString(json['room_number']),
      capacity: _safeToInt(json['capacity']),
      occupiedCount: _safeToInt(json['occupied_count']),
      availableSpots: _safeToInt(json['available_spots']),
      isFull: _safeToBool(json['is_full']),
      rent: _safeToDouble(json['rent']),
    );
  }
}

// ============================================================
// REVIEWMODEL - Safe parsing
// ============================================================
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

  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0.0;
      final parsed = double.tryParse(trimmed);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  static String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      name: _safeToString(json['name']),
      comment: _safeToString(json['comment']),
      rating: _safeToDouble(json['rating']),
      date: _safeToString(json['date']),
    );
  }
}