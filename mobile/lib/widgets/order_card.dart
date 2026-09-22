import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'status_badge.dart';

/// Matches the Figma order-card row: order number + status badge on
/// top, timestamp + item summary below, price pinned to the right.
class OrderCard extends StatelessWidget {
  final CafforaOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = DateFormat('MMM d, h:mm a').format(order.placedAt);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.orderNumber, style: theme.textTheme.titleLarge),
                        const SizedBox(width: 8),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formatted, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      order.itemsSummary,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
