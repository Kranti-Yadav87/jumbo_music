import 'package:flutter/material.dart';
import '../../screens/search_tab.dart';

/// Sub-bar below categories showing item count, sorting toggle, options button, and search button.
class LibrarySubBar extends StatelessWidget {
  final int itemCount;
  final bool isAscending;
  final VoidCallback onToggleSort;
  final VoidCallback onOptionsTap;
  final bool isDark;

  const LibrarySubBar({
    super.key,
    required this.itemCount,
    required this.isAscending,
    required this.onToggleSort,
    required this.onOptionsTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            '$itemCount items',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onToggleSort,
            child: Row(
              children: [
                Text(
                  isAscending ? 'AZ' : 'ZA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                Icon(
                  isAscending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.menu_book_rounded,
              size: 18,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            onPressed: onOptionsTap,
          ),
          const SizedBox(width: 16),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchTab()),
              );
            },
          ),
        ],
      ),
    );
  }
}
