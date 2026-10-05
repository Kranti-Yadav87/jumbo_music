import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../edit_profile_dialog.dart';
import '../auth_dialog.dart';

/// Top avatar, user details, and profile action buttons header in ProfileScreen.
class ProfileAvatarHeader extends StatelessWidget {
  final DatabaseService db;
  final bool isDark;

  const ProfileAvatarHeader({
    super.key,
    required this.db,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Large Monogram Circular Avatar
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF2A2016),
                      Color(0xFF1A140E),
                      Color(0xFF0F0B08),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    db.userInitials,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFFFFD700),
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Camera / Edit Icon Badge
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => EditProfileDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E3A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF101016) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E3A).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Display Name
        Text(
          db.userName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          db.userEmail,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),

        // Jumbo User ID Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 14,
                color: Color(0xFF818CF8),
              ),
              const SizedBox(width: 6),
              Text(
                'ID: ${db.userId}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF818CF8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Cloud Sync',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // "Edit Profile" and "Sign In / Switch" Buttons
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () => EditProfileDialog.show(context),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF0F172A),
                side: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: Icon(
                db.isLoggedIn ? Icons.swap_horiz_rounded : Icons.login_rounded,
                size: 16,
              ),
              label: Text(
                db.isLoggedIn ? 'Switch ID' : 'Sign In / Register',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => AuthDialog.show(context),
            ),
          ],
        ),
      ],
    );
  }
}
