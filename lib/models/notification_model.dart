// lib/models/notification_model.dart
import 'dart:convert';

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

  // ============================================================
  // FIXED: Safe parsing for isRead - handles int 0/1 and bool
  // ============================================================
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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    if (value is bool) return value ? 1 : 0;
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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      createdAt: _parseDateTime(json['created_at']),
      // FIXED: Use _parseBool instead of direct cast
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