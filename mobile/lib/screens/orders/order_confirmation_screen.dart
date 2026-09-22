import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../widgets/status_badge.dart';

/// Shown right after checkout. Replaces the old order-pickup QR code
/// with a clear order summary — the order is now tied to a table (or
/// pickup) that was identified *before* checkout via TableScanScreen,
/// so there's no handoff QR to show any more. Also surfaces the
/// (simulated) payment result recorded right after the order was placed.
class OrderConfirmationScreen extends StatelessWidget {
  final CafforaOrder order;
  final Payment? payment;
  const OrderConfirmationScreen({super.key, required this.order, this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 56),
                  const SizedBox(height: 16),
                  Text('Order ${order.orderNumber}', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      StatusBadge(status: order.status),
                      if (order.isDineIn)
                        Chip(
                          label: Text('Table ${order.tableNumber}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      else
                        const Chip(
                          label: Text('Pickup'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (payment != null) _PaymentCard(payment: payment!) else _PaymentPendingCard(theme: theme),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order summary', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${item.name} x${item.quantity}', style: theme.textTheme.bodyMedium)),
                            Text('\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total paid', style: theme.textTheme.bodyMedium),
                        Text('\$${order.total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.orders, (r) => false),
              child: const Text('Track my order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.isPaid ? 'Paid' : payment.status} via ${paymentMethodLabel(payment.method)}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Simulated payment — no real charge was made.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPendingCard extends StatelessWidget {
  final ThemeData theme;
  const _PaymentPendingCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your order is placed — we couldn\'t confirm the payment record just now, but nothing was charged (this is a simulated flow).',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
