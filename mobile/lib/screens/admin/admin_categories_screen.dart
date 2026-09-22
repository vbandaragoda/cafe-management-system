import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

/// Read-only categories list for admins (`GET /api/categories`).
/// There's no dedicated create/edit endpoint exposed to mobile yet, so
/// this screen's job is simply to let an admin see what categories
/// exist — full CRUD can be added later without changing this screen's
/// shape once the backend exposes it.
class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: admin.categories.isEmpty
          ? Center(child: Text('No categories yet.', style: theme.textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admin.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = admin.categories[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.category_rounded, color: theme.colorScheme.primary),
                    title: Text(c.name),
                    subtitle: c.description.isNotEmpty ? Text(c.description) : null,
                  ),
                );
              },
            ),
    );
  }
}
