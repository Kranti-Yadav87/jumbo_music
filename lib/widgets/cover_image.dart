import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Shared production-grade cover image widget using [CachedNetworkImage]
/// with memory-cache dimension limits (`memCacheWidth` / `memCacheHeight`),
/// disk caching, placeholder shimmer, and fallback icons.
class CoverImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData fallbackIcon;
  final Color? fallbackBgColor;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.music_note_rounded,
    this.fallbackBgColor,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = imageUrl?.trim() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg =
        fallbackBgColor ??
        (isDark ? const Color(0xFF131F38) : const Color(0xFFE2E8F0));
    final defaultIconColor = isDark ? Colors.white38 : Colors.black38;

    final defaultFallback = Container(
      width: width,
      height: height,
      color: defaultBg,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: defaultIconColor,
        size: (width != null && width! < 40) ? 18 : 24,
      ),
    );

    if (validUrl.isEmpty ||
        (!validUrl.startsWith('http://') && !validUrl.startsWith('https://'))) {
      if (borderRadius != null && borderRadius != BorderRadius.zero) {
        return ClipRRect(borderRadius: borderRadius!, child: defaultFallback);
      }
      return defaultFallback;
    }

    final calculatedMemWidth =
        memCacheWidth ??
        ((width != null && width! > 0) ? (width! * 2).toInt() : null);
    final calculatedMemHeight =
        memCacheHeight ??
        ((height != null && height! > 0) ? (height! * 2).toInt() : null);

    final imageWidget = CachedNetworkImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: calculatedMemWidth,
      memCacheHeight: calculatedMemHeight,
      maxWidthDiskCache: calculatedMemWidth != null
          ? calculatedMemWidth * 2
          : 1000,
      maxHeightDiskCache: calculatedMemHeight != null
          ? calculatedMemHeight * 2
          : 1000,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: defaultBg,
            alignment: Alignment.center,
            child: Icon(
              fallbackIcon,
              color: defaultIconColor.withOpacity(0.5),
              size: (width != null && width! < 40) ? 16 : 22,
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ?? defaultFallback,
    );

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
