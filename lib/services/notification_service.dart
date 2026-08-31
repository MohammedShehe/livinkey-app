import 'dart:async';
import 'package:livinkey/models/auth_models.dart';
import '../services/api_service.dart';

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

  // Stream for unread count so UI can react
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

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
      // swallow – UI will just keep old data
    }
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _refreshTenant() async {
    try {
      final countRes = await _api.getUnreadTenantCount();
      if (countRes['success'] == true) {
        final count = countRes['unreadCount'];
        if (count != null) {
          _unreadCount = _safeParseInt(count);
          _unreadCountController.add(_unreadCount);
        }
      }

      final notificationsRes = await _api.getTenantNotifications(limit: 100);
      if (notificationsRes['success'] == true &&
          notificationsRes['data'] != null) {
        final data = notificationsRes['data'];
        if (data is List) {
          _notifications =
              data.map((n) => NotificationModel.fromJson(n)).toList();
          _notificationsController.add(List.from(_notifications));
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _refreshGuest() async {
    try {
      final countRes = await _api.getUnreadGuestCount();
      if (countRes['success'] == true) {
        final count = countRes['unreadCount'];
        if (count != null) {
          _unreadCount = _safeParseInt(count);
          _unreadCountController.add(_unreadCount);
        }
      }

      final notificationsRes = await _api.getGuestNotifications(limit: 100);
      if (notificationsRes['success'] == true &&
          notificationsRes['data'] != null) {
        final data = notificationsRes['data'];
        if (data is List) {
          _notifications =
              data.map((n) => NotificationModel.fromJson(n)).toList();
          _notificationsController.add(List.from(_notifications));
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> markAsRead(int id, {bool isTenant = true}) async {
    try {
      if (isTenant) {
        await _api.markTenantNotificationRead(id);
      } else {
        await _api.markGuestNotificationRead(id);
      }

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        _unreadCountController.add(_unreadCount);
        _notificationsController.add(List.from(_notifications));
      }
      await refresh(isTenant: isTenant);
    } catch (e) {
      // ignore
    }
  }

  Future<void> markAllAsRead({bool isTenant = true}) async {
    try {
      if (isTenant) {
        await _api.markAllTenantNotificationsRead();
      } else {
        await _api.markAllGuestNotificationsRead();
      }

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      _unreadCountController.add(0);
      _notificationsController.add(List.from(_notifications));
      await refresh(isTenant: isTenant);
    } catch (e) {
      // ignore
    }
  }

  Future<void> deleteNotification(int id, {bool isTenant = true}) async {
    try {
      final response = isTenant
          ? await _api.deleteTenantNotification(id)
          : await _api.deleteGuestNotification(id);

      if (response['success'] == true) {
        _notifications.removeWhere((n) => n.id == id);
        _notificationsController.add(List.from(_notifications));
        await refresh(isTenant: isTenant);
      } else {
        throw Exception(response['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      rethrow;
    }
  }

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  void dispose() {
    _notificationsController.close();
    _unreadCountController.close();
  }
}