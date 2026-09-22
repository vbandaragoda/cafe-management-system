import 'product.dart';

/// A line in the in-memory cart. Prices shown here are for display only —
/// the backend always recomputes authoritative totals from current
/// product prices when the order is actually placed.
class CartItem {
  final Product product;
  int quantity;
  String note;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.note = '',
  });

  double get lineTotal => product.price * quantity;
}
