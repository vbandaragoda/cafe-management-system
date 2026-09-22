import 'package:flutter/material.dart';
import '../models/product.dart';
import 'network_food_image.dart';

/// Matches the Figma menu-card: 80x80 thumbnail, title/description
/// column, price + "Add to Cart" action row. (Renamed from
/// MenuItemCard — same widget, now backed by the Product model.)
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onAdd, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodySmall?.color;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkFoodImage(url: product.imageUrl, width: 80, height: 80, borderRadius: BorderRadius.circular(12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const Spacer(),
                        if (product.isAvailable)
                          ElevatedButton(
                            onPressed: onAdd,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Add to Cart'),
                          )
                        else
                          Text(
                            'Sold Out',
                            style: theme.textTheme.labelSmall?.copyWith(color: secondary, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
