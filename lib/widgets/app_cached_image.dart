import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Production-grade cached network image widget with memory/disk caching,
/// smooth cross-fade animation, placeholder shimmer, and fallback icons.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData fallbackIcon;
  final Color? fallbackBgColor;

  const AppCachedImage({
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
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = imageUrl.trim();
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
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: defaultFallback,
      );
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) =>
          placeholder ??
          _ShimmerPlaceholder(
            width: width,
            height: height,
            backgroundColor: defaultBg,
          ),
      errorWidget: (context, url, error) => errorWidget ?? defaultFallback,
    );

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final Color backgroundColor;

  const _ShimmerPlaceholder({
    this.width,
    this.height,
    required this.backgroundColor,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                widget.backgroundColor,
                widget.backgroundColor.withOpacity(0.4),
                widget.backgroundColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
