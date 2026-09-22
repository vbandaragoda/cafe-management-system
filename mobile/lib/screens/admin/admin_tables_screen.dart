import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/admin_provider.dart';

/// Admin's printable table QR codes (`GET /api/tables`) — a
/// legitimate reuse of `qr_flutter` now that the old pickup-order QR
/// flow is gone. Each card encodes `cafe://table/{tableNumber}`, the
/// exact payload `TableScanScreen` expects a customer's camera to
/// read, so these can be printed and placed on the physical tables.
class AdminTablesScreen extends StatelessWidget {
  const AdminTablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tables')),
      body: admin.tables.isEmpty
          ? Center(child: Text('No tables yet.', style: theme.textTheme.bodyMedium))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: admin.tables.length,
              itemBuilder: (context, i) {
                final t = admin.tables[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: QrImageView(
                          data: 'cafe://table/${t.tableNumber}',
                          size: 100,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Table ${t.tableNumber}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
