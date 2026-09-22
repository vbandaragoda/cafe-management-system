import '../models/admin_dashboard.dart';
import 'api_client.dart';

/// Wraps /api/admin/dashboard — a cross-table aggregate (orders join
/// order_items join menu_items) computed server-side and reflected
/// directly in the Admin screen's metric cards.
class AdminService {
  final ApiClient _client;
  AdminService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AdminDashboard> dashboard() async {
    final json = await _client.get('/admin/dashboard') as Map<String, dynamic>;
    return AdminDashboard.fromJson(json);
  }
}
