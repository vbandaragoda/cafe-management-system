import '../models/cart_item.dart';
import '../models/order.dart';
import 'api_client.dart';

/// Wraps /api/orders on the Caffora backend.
class OrderService {
  final ApiClient _client;
  OrderService({ApiClient? client}) : _client = client ?? ApiClient();

  /// [tableId] comes from the currently-scanned table (see
  /// TableProvider) — null means a plain pickup order.
  Future<CafforaOrder> placeOrder(List<CartItem> cartItems, {int? tableId, String pickupType = 'COUNTER'}) async {
    final body = {
      'items': cartItems
          .map((c) => {
                'productId': c.product.id,
                'quantity': c.quantity,
                if (c.note.trim().isNotEmpty) 'note': c.note.trim(),
              })
          .toList(),
      if (tableId != null) 'tableId': tableId,
      'pickupType': pickupType,
    };
    final json = await _client.post('/orders', body: body) as Map<String, dynamic>;
    return CafforaOrder.fromJson(json);
  }

  Future<List<CafforaOrder>> myOrders() async {
    final json = await _client.get('/orders/my');
    return (json as List<dynamic>? ?? []).map((e) => CafforaOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CafforaOrder> getOrder(int id) async {
    final json = await _client.get('/orders/$id') as Map<String, dynamic>;
    return CafforaOrder.fromJson(json);
  }

  /// ADMIN only. [activeOnly] maps to `?active=true` — the live kitchen queue.
  Future<List<CafforaOrder>> allOrders({bool activeOnly = false}) async {
    final json = await _client.get('/orders', query: activeOnly ? {'active': 'true'} : null);
    return (json as List<dynamic>? ?? []).map((e) => CafforaOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// ADMIN only. Advances (or sets) an order's status from the queue.
  Future<CafforaOrder> updateStatus(int id, OrderStatus status) async {
    final json = await _client.put('/orders/$id/status', body: {'status': orderStatusToApiString(status)})
        as Map<String, dynamic>;
    return CafforaOrder.fromJson(json);
  }
}
