import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/cart_item_row.dart';
import '../../widgets/caffora_bottom_nav.dart';
import '../orders/order_confirmation_screen.dart';

/// Matches the Figma mobile-cart frame: item list with quantity
/// steppers, a payment-method picker, then a summary block (subtotal /
/// pickup fee / total) and a full-width "Place Order" button.
/// Registered-user-only — AppRouter redirects guests to /auth before
/// reaching this screen.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _paymentService = PaymentService();
  PaymentMethod _method = PaymentMethod.card;
  bool _placing = false;

  Future<void> _placeOrder(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).pushNamed(AppRoutes.auth);
      return;
    }
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final table = context.read<TableProvider>().currentTable;

    setState(() => _placing = true);
    final placed = await orderProvider.placeOrder(
      cart.items,
      tableId: table?.id,
      pickupType: table != null ? 'TABLE' : 'COUNTER',
    );
    if (!context.mounted) return;

    if (placed == null) {
      setState(() => _placing = false);
      if (orderProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(orderProvider.error!)));
      }
      return;
    }

    // Simulated payment — no real gateway is involved; the backend
    // marks it PAID immediately. If this call fails for some reason
    // the order itself still went through, so we don't block on it.
    Payment? payment;
    try {
      payment = await _paymentService.recordPayment(placed.id, _method);
    } catch (_) {
      payment = null;
    }
    if (!context.mounted) return;

    cart.clear();
    setState(() => _placing = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: placed, payment: payment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final busy = _placing || orderProvider.isLoading;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('My Cart', style: theme.textTheme.headlineMedium)),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 56, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('Add something delicious from the menu.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.menu, (r) => false),
                      child: const Text('Browse Menu'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final entry = cart.items[i];
                      return CartItemRow(
                        cartItem: entry,
                        onQuantityChanged: (q) => cart.updateQuantity(entry.product.id, q),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(top: BorderSide(color: theme.colorScheme.outline)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Pay with', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final m in PaymentMethod.values)
                            ChoiceChip(
                              label: Text(paymentMethodLabel(m)),
                              selected: _method == m,
                              onSelected: (_) => setState(() => _method = m),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Simulated payment — no real charge is made.',
                          style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _summaryRow(theme, 'Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _summaryRow(theme, 'Tax (8%)', '\$${cart.tax.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _summaryRow(theme, 'Register Pick-up Fee', '\$${cart.pickupFee.toStringAsFixed(2)}'),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Payment', style: theme.textTheme.titleLarge),
                          Text(
                            '\$${cart.total.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: busy ? null : () => _placeOrder(context),
                        child: busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Place Order (\$${cart.total.toStringAsFixed(2)})'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 2),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
