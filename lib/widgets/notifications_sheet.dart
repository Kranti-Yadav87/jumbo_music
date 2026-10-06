import 'package:flutter/material.dart';
import '../screens/friends_screen.dart';
import '../services/database_service.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notif,
    DatabaseService db,
  ) {
    final notifId = notif['id'] as String?;
    if (notifId != null) {
      db.markNotificationAsRead(notifId);
    }

    final type = notif['type'] as String? ?? 'system';

    if (type == 'friend' || type == 'invite' || type == 'friend_request') {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendsScreen()),
      );
    } else if (type == 'playlist') {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: db,
      builder: (context, _) {
        final notifs = db.notifications;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14141E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E3A).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFFF5E3A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${notifs.length} recent updates',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (notifs.isNotEmpty)
                      TextButton(
                        onPressed: () => db.clearNotifications(),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFFFF5E3A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 24, thickness: 0.6),

              // Notifications List
              Flexible(
                child: notifs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48,
                          horizontal: 20,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 56,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Friend activity, requests, and playlist invites will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = notifs[index];
                          final notifId = notif['id'] as String? ?? 'n_$index';
                          final type = notif['type'] as String? ?? 'system';
                          final isRead = notif['isRead'] as bool? ?? false;

                          IconData iconData = Icons.notifications_rounded;
                          Color iconColor = const Color(0xFFFF5E3A);
                          if (type == 'friend' || type == 'friend_request') {
                            iconData = Icons.person_rounded;
                            iconColor = const Color(0xFF38BDF8);
                          } else if (type == 'playlist') {
                            iconData = Icons.queue_music_rounded;
                            iconColor = const Color(0xFFA855F7);
                          } else if (type == 'invite') {
                            iconData = Icons.group_add_rounded;
                            iconColor = const Color(0xFF10B981);
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _handleNotificationTap(
                                context,
                                notif,
                                db,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? (isRead
                                            ? const Color(0xFF1A1A24)
                                            : const Color(0xFF222232))
                                      : (isRead
                                            ? const Color(0xFFF8FAFC)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isRead
                                        ? Colors.transparent
                                        : (isDark
                                              ? const Color(0xFFFF5E3A).withOpacity(0.3)
                                              : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif['title'] as String? ??
                                                      'Notification',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFF5E3A),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            notif['message'] as String? ?? '',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF475569),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => db.deleteNotification(notifId),
                                      tooltip: 'Dismiss',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
