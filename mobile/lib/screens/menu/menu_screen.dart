import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/caffora_bottom_nav.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/product_card.dart';

/// Matches the Figma mobile-menu frame: search header, horizontal
/// category chip row, and a vertical list of product cards. The main
/// data-view screen for the customer-facing side of the app. When a
/// table has been scanned (TableProvider), a banner up top makes that
/// visible and lets the customer switch back to pickup.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = context.read<ProductProvider>();
      if (products.items.isEmpty) products.load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final products = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final table = context.watch<TableProvider>();
    final items = products.filtered;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Artisanal Menu', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            tooltip: table.hasTable ? 'Scan a different table' : 'Scan table QR to order',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tableScan),
          ),
        ],
      ),
      body: Column(
        children: [
          if (products.isShowingCachedData) const OfflineBanner(),
          if (table.hasTable) _TableBanner(tableNumber: table.currentTable!.tableNumber, onClear: () => table.clearTable()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => products.setSearch(v),
              decoration: const InputDecoration(
                hintText: 'Search flat white, cookie...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isAll = i == 0;
                  final label = isAll ? 'All' : products.categories[i - 1].name;
                  final categoryId = isAll ? null : products.categories[i - 1].id;
                  final active = products.selectedCategoryId == categoryId;
                  return ChoiceChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) => products.setCategory(categoryId),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.cardColor,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: StadiumBorder(side: BorderSide(color: theme.colorScheme.outline)),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: products.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.error != null && items.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(products.error!, textAlign: TextAlign.center)))
                    : RefreshIndicator(
                        onRefresh: () => products.load(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            return ProductCard(
                              product: item,
                              onAdd: () {
                                if (!auth.isAuthenticated) {
                                  Navigator.of(context).pushNamed(AppRoutes.auth);
                                  return;
                                }
                                context.read<CartProvider>().add(item);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text('Added ${item.name} to cart'), duration: const Duration(milliseconds: 900)));
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 1),
    );
  }
}

class _TableBanner extends StatelessWidget {
  final String tableNumber;
  final VoidCallback onClear;
  const _TableBanner({required this.tableNumber, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.primary,
      child: Row(
        children: [
          const Icon(Icons.table_restaurant_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ordering for Table $tableNumber',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Text(
              'Switch to pickup',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
