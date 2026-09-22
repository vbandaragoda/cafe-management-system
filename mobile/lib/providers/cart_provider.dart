import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Registered-user-only cart state (see AuthProvider gating in the UI
/// layer). Client-side totals shown here are for display; the backend
/// recomputes authoritative totals from live prices at checkout.
class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  static const double taxRate = 0.08;
  static const double pickupFee = 0.50;

  List<CartItem> get items => _items.values.toList(growable: false);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (sum, c) => sum + c.quantity);

  double get subtotal => _items.values.fold(0.0, (sum, c) => sum + c.lineTotal);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax + (isEmpty ? 0 : pickupFee);

  void add(Product product, {int quantity = 1, String note = ''}) {
    final existing = _items[product.id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity, note: note);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final existing = _items[productId];
    if (existing == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      existing.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
