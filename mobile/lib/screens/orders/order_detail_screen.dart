import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../services/api_exception.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/status_badge.dart';

/// Live single-order tracker: polls GET /api/orders/{id} so the
/// status badge stays current if an admin updates this exact order
/// while the customer has the screen open. Shows a clear order-status
/// summary (number, status, table/pickup, items, totals) and the
/// (simulated) payment result — no QR code any more, since the old
/// pickup-handoff QR flow has been replaced by table-QR ordering.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  final _paymentService = PaymentService();
  CafforaOrder? _order;
  Payment? _payment;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchPayment();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _fetch(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    try {
      final order = await _orderService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!silent && mounted) setState(() => _error = e.message);
    } catch (_) {
      if (!silent && mounted) setState(() => _error = 'Could not refresh this order right now.');
    }
  }

  Future<void> _fetchPayment() async {
    try {
      final payment = await _paymentService.byOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _payment = payment);
    } catch (_) {
      // Payment status is a nice-to-have on this screen — a failed
      // fetch here shouldn't block the order details from showing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text(order?.orderNumber ?? 'Order')),
      body: order == null
          ? Center(child: Text(_error ?? '', style: theme.textTheme.bodyMedium))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.orderNumber, style: theme.textTheme.headlineMedium),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(order.isDineIn ? 'Table ${order.tableNumber}' : 'Pickup'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (_payment != null)
                        Chip(
                          avatar: const Icon(Icons.verified_rounded, size: 16),
                          label: Text('${_payment!.isPaid ? 'Paid' : _payment!.status} · ${paymentMethodLabel(_payment!.method)}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items', style: theme.textTheme.titleMedium),
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
                          _row(theme, 'Subtotal', order.subtotal),
                          _row(theme, 'Tax', order.tax),
                          _row(theme, 'Pickup fee', order.pickupFee),
                          const Divider(height: 24),
                          _row(theme, 'Total', order.total, emphasize: true),
                          if (_payment != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Simulated payment — no real charge was made.',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(ThemeData theme, String label, double value, {bool emphasize = false}) {
    final style = emphasize ? theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary) : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: emphasize ? theme.textTheme.titleLarge : theme.textTheme.bodyMedium),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
