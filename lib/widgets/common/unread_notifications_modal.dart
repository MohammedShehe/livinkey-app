import 'package:flutter/material.dart';
import 'package:livinkey/models/auth_models.dart';
import 'package:livinkey/utils/constants.dart';

class UnreadNotificationsModal extends StatelessWidget {
  final List<NotificationModel> notifications;
  final bool isTenant;
  final VoidCallback onMarkAllRead;
  final void Function(NotificationModel) onTapNotification;

  const UnreadNotificationsModal({
    super.key,
    required this.notifications,
    required this.isTenant,
    required this.onMarkAllRead,
    required this.onTapNotification,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).toList();

    return Dialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kLivinkeyGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: kLivinkeyGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unread Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${unread.length} new',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: unread.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Colors.white10,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final n = unread[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: kLivinkeyGreen.withOpacity(0.15),
                      child: Icon(
                        _iconForType(n.type),
                        color: kLivinkeyGreen,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      n.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onTapNotification(n);
                    },
                  );
                },
              ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        onMarkAllRead();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: kLivinkeyGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLivinkeyGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('bill') || t.contains('payment')) {
      return Icons.receipt_long_rounded;
    }
    if (t.contains('maintenance')) {
      return Icons.build_rounded;
    }
    if (t.contains('document') || t.contains('efrro')) {
      return Icons.description_rounded;
    }
    return Icons.notifications_rounded;
  }
}