import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Wraps CachedNetworkImage with a graceful offline/broken-link
/// fallback (a coffee-cup glyph on a tinted tile) instead of the
/// default broken-image icon — keeps the "no dead content" screens
/// looking finished even with zero connectivity.
class NetworkFoodImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const NetworkFoodImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? AppColors.darkNeutralTint : AppColors.lightSearchFill;

    return ClipRRect(
      borderRadius: borderRadius,
      child: url.isEmpty
          ? _fallback(placeholderColor)
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, _) => _fallback(placeholderColor),
              errorWidget: (context, _, __) => _fallback(placeholderColor),
            ),
    );
  }

  Widget _fallback(Color color) {
    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      child: Icon(Icons.local_cafe_rounded, color: AppColors.lightAccent, size: width * 0.4),
    );
  }
}
