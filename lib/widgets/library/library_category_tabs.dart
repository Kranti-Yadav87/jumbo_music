import 'package:flutter/material.dart';

/// Horizontal category selector tabs in LibraryTab (Playlists, Songs, Albums, Artists).
class LibraryCategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final bool isDark;

  const LibraryCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return InkWell(
            onTap: () => onSelectCategory(cat),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                Container(
                  height: 2.5,
                  width: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0EA5E9))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
