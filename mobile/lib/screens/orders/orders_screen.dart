import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/caffora_bottom_nav.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Matches the Figma mobile-orders frame, including the offline
/// banner. Polls the backend every few seconds so an admin's status
/// update (e.g. Preparing -> Ready after a QR scan) shows up here
/// automatically without a manual refresh.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.load();
      provider.startPolling();
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('My Orders', style: theme.textTheme.headlineMedium)),
      body: Column(
        children: [
          if (orders.isShowingCachedData) const OfflineBanner(),
          Expanded(
            child: orders.isLoading && orders.orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : orders.orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            orders.error ?? 'No orders yet — your first cup is a tap away.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => orders.load(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: orders.orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final order = orders.orders[i];
                            return OrderCard(
                              order: order,
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 3),
    );
  }
}
