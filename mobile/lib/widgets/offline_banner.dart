import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// "You are offline — showing cached data" banner, matching the
/// pale-yellow strip seen at the top of the Figma orders-dark frame.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkWarningTint : AppColors.lightWarningTint;
    final fg = isDark ? AppColors.darkWarning : AppColors.lightWarning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are offline — showing cached data',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
