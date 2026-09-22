import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/caffora_bottom_nav.dart';
import '../../widgets/network_food_image.dart';

/// Matches the Figma mobile-home frame: app header with logo +
/// avatar, welcome block, promo banner, "Today's favorites"
/// horizontal carousel, and primary CTAs. "Scan Table QR to Order" is
/// the primary entry point for dine-in customers; "Browse Menu" stays
/// available underneath for pickup/guest browsing without a table.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final firstName = (auth.user?.name.split(' ').first) ?? 'there';
    final featured = products.items.where((m) => m.isAvailable).take(6).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Caffora', style: theme.textTheme.titleLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? AppColors.darkNeutralTint : AppColors.lightSearchFill,
              child: Icon(Icons.person_rounded, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => products.load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $firstName 👋', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                auth.isGuest
                    ? 'Browsing as guest — sign in to order ahead'
                    : 'At a table? Scan its QR code to order right to it.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _PromoBanner(isDark: isDark),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's favorites", style: theme.textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.menu, (r) => false),
                    child: Text('View All', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: products.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : featured.isEmpty
                        ? Center(child: Text('No items yet', style: theme.textTheme.bodyMedium))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featured.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, i) => _FeaturedCard(product: featured[i]),
                          ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tableScan),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Table QR to Order'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.menu, (r) => false),
                child: const Text('Browse Menu for Pickup'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 0),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final bool isDark;
  const _PromoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightAccentTint,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(999)),
            child: const Text('MEMBER PERK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Text('Your 5th cup is on us', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text('Every order stamps your loyalty card automatically.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Product product;
  const _FeaturedCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 162,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkFoodImage(url: product.imageUrl, width: 162, height: 110, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
