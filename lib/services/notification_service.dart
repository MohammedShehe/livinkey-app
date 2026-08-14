// lib/services/notification_service.dart
import 'dart:async';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  final StreamController<List<NotificationModel>> _notificationsController = 
      StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get notificationsStream => 
      _notificationsController.stream;

  List<NotificationModel> get notifications => List.from(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize with sample notifications
  void initialize() {
    _notifications.addAll([
      NotificationModel(
        id: '1',
        title: 'Rent Payment Due',
        message: 'Your rent of ₹8,500 is due in 3 days. Please pay before 14 Aug, 2026.',
        type: 'bill',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        actionRoute: '/payments',
      ),
      NotificationModel(
        id: '2',
        title: 'Maintenance Request Update',
        message: 'Your maintenance request for "Leaking pipe" has been marked as In Progress.',
        type: 'maintenance',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        actionRoute: '/maintenance',
      ),
      NotificationModel(
        id: '3',
        title: 'Document Reminder',
        message: 'Please upload your updated ID proof documents by 20 Aug, 2026.',
        type: 'document',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        actionRoute: '/documents',
      ),
      NotificationModel(
        id: '4',
        title: 'Payment Confirmed',
        message: 'Your payment of ₹8,500 for July 2026 has been confirmed.',
        type: 'bill',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        title: 'New PG Available',
        message: 'A new PG "Sunshine PG" is now available near your location.',
        type: 'general',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
    
    _notificationsController.add(List.from(_notifications));
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _notificationsController.add(List.from(_notifications));
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationsController.add(List.from(_notifications));
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationsController.add(List.from(_notifications));
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _notificationsController.add(List.from(_notifications));
  }

  void clearAllNotifications() {
    _notifications.clear();
    _notificationsController.add(List.from(_notifications));
  }

  void dispose() {
    _notificationsController.close();
  }
}