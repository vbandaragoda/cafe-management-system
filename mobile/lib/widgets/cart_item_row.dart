import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/cart_item.dart';
import 'network_food_image.dart';

/// Matches the Figma cart-item-card: 60x60 thumbnail, title/note/price
/// column, and a pill-shaped quantity stepper on the right.
class CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final ValueChanged<int> onQuantityChanged;

  const CartItemRow({super.key, required this.cartItem, required this.onQuantityChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = cartItem.product;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            NetworkFoodImage(url: item.imageUrl, width: 60, height: 60, borderRadius: BorderRadius.circular(8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (cartItem.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(cartItem.note, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkNeutralTint : AppColors.lightSearchFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperButton(icon: Icons.remove, onTap: () => onQuantityChanged(cartItem.quantity - 1)),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${cartItem.quantity}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  _StepperButton(icon: Icons.add, onTap: () => onQuantityChanged(cartItem.quantity + 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
