import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: kFadeDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    
    _loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIXED: Load real notifications from API
  // ============================================================
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _notificationService.refresh(isTenant: true);
      if (mounted) {
        setState(() {
          _notifications = _notificationService.notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Failed to load notifications');
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await _loadNotifications();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  // ============================================================
  // FIXED: Mark notification as read with proper API call
  // ============================================================
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    
    try {
      await _notificationService.markAsRead(notification.id, isTenant: true);
      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            createdAt: notification.createdAt,
            isRead: true,
            entityId: notification.entityId,
            entityType: notification.entityType,
            link: notification.link,
            icon: notification.icon,
            color: notification.color,
          );
        }
      });
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to mark as read');
    }
  }

  // ============================================================
  // FIXED: Mark all notifications as read with proper API call
  // ============================================================
  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty) return;
    
    try {
      await _notificationService.markAllAsRead(isTenant: true);
      // Update all notifications
      setState(() {
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
      });
      SnackbarHelper.showSuccess(context, 'All notifications marked as read');
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to mark all as read');
    }
  }

  // ============================================================
  // FIXED: Delete notification
  // ============================================================
  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id, isTenant: true);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      SnackbarHelper.show(context, 'Notification dismissed');
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to delete notification');
    }
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'bill_created':
        return '📄';
      case 'bill_paid':
        return '✅';
      case 'bill_partially_paid':
        return '💳';
      case 'bill_fine_applied':
        return '💰';
      case 'maintenance_created':
        return '🔧';
      case 'maintenance_started':
        return '🔄';
      case 'maintenance_completed':
        return '✅';
      case 'document_reminder':
        return '📋';
      case 'efrro_expiry':
        return '🛂';
      case 'payment_reminder':
        return '💸';
      default:
        return '📢';
    }
  }

  Color _getTypeColor(String type) {
    if (type.contains('bill')) return Colors.orange;
    if (type.contains('maintenance')) return Colors.blue;
    if (type.contains('document') || type.contains('efrro')) return Colors.purple;
    if (type.contains('payment')) return Colors.red;
    return kLivinkeyGreen;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day} ${_monthName(timestamp.month)}, ${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        backgroundColor: kLivinkeyBlack,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: kLivinkeyGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: kLivinkeyGreen,
                  backgroundColor: kLivinkeyBlack,
                  child: _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withOpacity(0.05),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationItem(notification);
                          },
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIXED: Notification item with proper read handling
  // ============================================================
  Widget _buildNotificationItem(NotificationModel notification) {
    final String key = notification.id.toString();
    final bool isUnread = !notification.isRead;

    return Dismissible(
      key: Key(key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            _markAsRead(notification);
          }
          // Navigate to action route if available
          if (notification.link != null) {
            Navigator.pop(context, notification.link);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isUnread 
                ? kLivinkeyGreen.withOpacity(0.06) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: kLivinkeyGreen.withOpacity(0.15),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getTypeIcon(notification.type),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: isUnread ? Colors.white : Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!isUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Read',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: kLivinkeyGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: isUnread 
                            ? Colors.white.withOpacity(0.8) 
                            : Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}