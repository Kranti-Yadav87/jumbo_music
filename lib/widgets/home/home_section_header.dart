import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onArrowTap;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppThemeManager.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppThemeManager.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onArrowTap != null)
            InkWell(
              onTap: onArrowTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: textColor, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
