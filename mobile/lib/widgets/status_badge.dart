import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/order.dart';

/// The 4-color status pill seen on order cards — colors extracted
/// directly from the Figma orders-light frame (Preparing=blue,
/// Ready=green, Completed=neutral, Pending=amber).
class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = _colors(status, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  (Color, Color) _colors(OrderStatus status, bool isDark) {
    switch (status) {
      case OrderStatus.preparing:
        return isDark ? (AppColors.darkInfoTint, AppColors.darkInfo) : (AppColors.lightInfoTint, AppColors.lightInfo);
      case OrderStatus.ready:
        return isDark
            ? (AppColors.darkSuccessTint, AppColors.darkSuccess)
            : (AppColors.lightSuccessTint, AppColors.lightSuccess);
      case OrderStatus.completed:
        return isDark
            ? (AppColors.darkNeutralTint, AppColors.darkTextSecondary)
            : (AppColors.lightNeutralTint, AppColors.lightTextSecondary);
      case OrderStatus.pending:
        return isDark
            ? (AppColors.darkWarningTint, AppColors.darkWarning)
            : (AppColors.lightWarningTint, AppColors.lightWarning);
    }
  }
}
