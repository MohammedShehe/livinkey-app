// lib/services/notification_service.dart
import 'dart:async';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _api = ApiService();
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;

  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  List<NotificationModel> get notifications => List.from(_notifications);
  int get unreadCount => _unreadCount;

  Future<void> initialize({bool isTenant = true}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    await refresh(isTenant: isTenant);
  }

  Future<void> refresh({bool isTenant = true}) async {
    try {
      if (isTenant) {
        await _refreshTenant();
      } else {
        await _refreshGuest();
      }
    } catch (e) {
      print('Notification refresh error: $e');
    }
  }

  // ============================================================
  // FIXED: Safe parsing for notification responses
  // ============================================================
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _safeParseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  Future<void> _refreshTenant() async {
    try {
      // Get unread count - safe parsing
      final countRes = await _api.getUnreadTenantCount();
      if (countRes['success'] == true) {
        final count = countRes['unreadCount'];
        if (count != null) {
          _unreadCount = _safeParseInt(count);
        }
      }

      // Get all notifications
      final notificationsRes = await _api.getTenantNotifications(limit: 100);
      if (notificationsRes['success'] == true && notificationsRes['data'] != null) {
        final data = notificationsRes['data'];
        if (data is List) {
          _notifications = data
              .map((n) => NotificationModel.fromJson(n))
              .toList();
          _notificationsController.add(List.from(_notifications));
        }
      }
    } catch (e) {
      print('_refreshTenant error: $e');
    }
  }

  Future<void> _refreshGuest() async {
    try {
      final countRes = await _api.getUnreadGuestCount();
      if (countRes['success'] == true) {
        final count = countRes['unreadCount'];
        if (count != null) {
          _unreadCount = _safeParseInt(count);
        }
      }

      final notificationsRes = await _api.getGuestNotifications(limit: 100);
      if (notificationsRes['success'] == true && notificationsRes['data'] != null) {
        final data = notificationsRes['data'];
        if (data is List) {
          _notifications = data
              .map((n) => NotificationModel.fromJson(n))
              .toList();
          _notificationsController.add(List.from(_notifications));
        }
      }
    } catch (e) {
      print('_refreshGuest error: $e');
    }
  }

  Future<void> markAsRead(int id, {bool isTenant = true}) async {
    try {
      if (isTenant) {
        await _api.markTenantNotificationRead(id);
      } else {
        await _api.markGuestNotificationRead(id);
      }
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          entityId: _notifications[index].entityId,
          entityType: _notifications[index].entityType,
          link: _notifications[index].link,
          icon: _notifications[index].icon,
          color: _notifications[index].color,
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        _notificationsController.add(List.from(_notifications));
      }
      await refresh(isTenant: isTenant);
    } catch (e) {
      print('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead({bool isTenant = true}) async {
    try {
      if (isTenant) {
        await _api.markAllTenantNotificationsRead();
      } else {
        await _api.markAllGuestNotificationsRead();
      }
      // Update local state
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        createdAt: n.createdAt,
        isRead: true,
        entityId: n.entityId,
        entityType: n.entityType,
        link: n.link,
        icon: n.icon,
        color: n.color,
      )).toList();
      _unreadCount = 0;
      _notificationsController.add(List.from(_notifications));
      await refresh(isTenant: isTenant);
    } catch (e) {
      print('markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(int id, {bool isTenant = true}) async {
    try {
      _notifications.removeWhere((n) => n.id == id);
      _notificationsController.add(List.from(_notifications));
    } catch (e) {
      print('deleteNotification error: $e');
    }
  }

  void dispose() {
    _notificationsController.close();
  }
}