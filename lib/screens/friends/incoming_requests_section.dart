import 'package:flutter/material.dart';
import '../../models/friend_request.dart';
import '../../services/friend_request_service.dart';

/// Section showing pending incoming friend requests with Accept & Decline buttons.
class IncomingRequestsSection extends StatelessWidget {
  final List<FriendRequest> requests;
  final bool isDark;

  const IncomingRequestsSection({
    super.key,
    required this.requests,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5E3A).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                color: Color(0xFFFF5E3A),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Incoming Requests',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E3A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => Divider(
              height: 16,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFF5E3A).withOpacity(0.2),
                    child: Text(
                      req.fromInitials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5E3A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.fromName.isNotEmpty ? req.fromName : 'Friend',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (req.fromEmail.isNotEmpty)
                          Text(
                            req.fromEmail,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Decline Button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Decline',
                    onPressed: () async {
                      await FriendRequestService.instance.declineFriendRequest(
                        req,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request declined.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  // Accept Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () async {
                      await FriendRequestService.instance.acceptFriendRequest(
                        req,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Accepted request from ${req.fromName.isNotEmpty ? req.fromName : req.fromEmail}! 🎉',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
