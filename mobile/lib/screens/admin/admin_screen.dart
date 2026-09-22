import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_dashboard.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/caffora_bottom_nav.dart';
import '../../widgets/network_food_image.dart';
import '../../widgets/status_badge.dart';
import 'admin_categories_screen.dart';
import 'admin_product_form_screen.dart';
import 'admin_tables_screen.dart';

/// Matches the Figma mobile-admin frame: "SYSTEM ADMIN" pill, a
/// Manage Menu / Manage Orders segmented toggle, and the FAB. Also
/// surfaces the cross-table dashboard aggregate (today's gross sales,
/// active order count, average prep time) computed server-side by
/// GET /api/admin/dashboard, plus entry points into the Categories and
/// Tables lists (the latter doubling as printable table QR codes).
/// ADMIN-role gated by AppRouter.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _showingMenu = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cafe Manager', style: theme.textTheme.headlineMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: theme.colorScheme.onSurface, borderRadius: BorderRadius.circular(999)),
              child: Text('SYSTEM ADMIN',
                  style: TextStyle(color: theme.scaffoldBackgroundColor, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            tooltip: 'Categories',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCategoriesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.table_restaurant_rounded),
            tooltip: 'Tables',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminTablesScreen())),
          ),
        ],
      ),
      body: admin.isLoading && admin.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.loadAll(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  if (admin.dashboard != null) _DashboardCards(dashboard: admin.dashboard!),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toggleButton(
                            'Manage Menu',
                            _showingMenu,
                            theme,
                            isDark,
                            () => setState(() => _showingMenu = true),
                          ),
                        ),
                        Expanded(
                          child: _toggleButton(
                            'Manage Orders (${admin.queue.length})',
                            !_showingMenu,
                            theme,
                            isDark,
                            () => setState(() => _showingMenu = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_showingMenu) ..._productRows(admin, theme, isDark) else ..._orderRows(admin, theme),
                ],
              ),
            ),
      floatingActionButton: _showingMenu
          ? FloatingActionButton(
              backgroundColor: theme.colorScheme.primary,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminProductFormScreen())),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 4),
    );
  }

  Widget _toggleButton(String label, bool active, ThemeData theme, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? (isDark ? AppColors.darkAccentTint : AppColors.lightAccentTint) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: active ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  List<Widget> _productRows(AdminProvider admin, ThemeData theme, bool isDark) {
    if (admin.products.isEmpty) {
      return [Padding(padding: const EdgeInsets.all(24), child: Text('No products yet.', style: theme.textTheme.bodyMedium))];
    }
    return admin.products
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outline)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    NetworkFoodImage(url: item.imageUrl, width: 44, height: 44, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${item.categoryName} • \$${item.price.toStringAsFixed(2)}${item.isAvailable ? '' : ' • Sold Out'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(item.isAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                      tooltip: item.isAvailable ? 'Mark sold out' : 'Mark available',
                      onPressed: () => admin.toggleAvailability(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminProductFormScreen(existing: item))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      onPressed: () => _confirmDelete(item.id, item.name, admin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  void _confirmDelete(int id, String name, AdminProvider admin) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              admin.deleteProduct(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Widget> _orderRows(AdminProvider admin, ThemeData theme) {
    if (admin.queue.isEmpty) {
      return [Padding(padding: const EdgeInsets.all(24), child: Text('No active orders in the queue.', style: theme.textTheme.bodyMedium))];
    }
    return admin.queue
        .map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(order.orderNumber, style: theme.textTheme.titleMedium),
                            const SizedBox(width: 8),
                            StatusBadge(status: order.status),
                            if (order.isDineIn) ...[
                              const SizedBox(width: 8),
                              Text('Table ${order.tableNumber}', style: theme.textTheme.bodySmall),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text(order.itemsSummary, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    PopupMenuButton<OrderStatus>(
                      onSelected: (status) => admin.advanceOrderStatus(order.id, status),
                      itemBuilder: (context) => [
                        for (final s in [OrderStatus.preparing, OrderStatus.ready, OrderStatus.completed])
                          PopupMenuItem(value: s, child: Text('Mark ${orderStatusLabel(s)}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _DashboardCards extends StatelessWidget {
  final AdminDashboard dashboard;
  const _DashboardCards({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: _metricCard(theme, 'Sales Today', '\$${dashboard.todaysGrossSales.toStringAsFixed(2)}')),
        const SizedBox(width: 10),
        Expanded(child: _metricCard(theme, 'Active Orders', '${dashboard.activeOrderCount}')),
        const SizedBox(width: 10),
        Expanded(child: _metricCard(theme, 'Avg Prep', '${dashboard.averagePrepMinutes.toStringAsFixed(0)}m')),
      ],
    );
  }

  Widget _metricCard(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
