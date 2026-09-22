enum OrderStatus { pending, preparing, ready, completed }

OrderStatus orderStatusFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PREPARING':
      return OrderStatus.preparing;
    case 'READY':
      return OrderStatus.ready;
    case 'COMPLETED':
      return OrderStatus.completed;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToApiString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'PENDING';
    case OrderStatus.preparing:
      return 'PREPARING';
    case OrderStatus.ready:
      return 'READY';
    case OrderStatus.completed:
      return 'COMPLETED';
  }
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.ready:
      return 'Ready';
    case OrderStatus.completed:
      return 'Completed';
  }
}

class OrderLineItem {
  final int productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? note;

  const OrderLineItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      productId: json['productId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String?,
    );
  }
}

class CafforaOrder {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final double subtotal;
  final double pickupFee;
  final double tax;
  final double total;
  final DateTime placedAt;
  final List<OrderLineItem> items;

  /// Non-null when this order was placed for a scanned table (dine-in);
  /// null for a plain pickup order.
  final int? tableId;
  final String? tableNumber;

  const CafforaOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.pickupFee,
    required this.tax,
    required this.total,
    required this.placedAt,
    required this.items,
    this.tableId,
    this.tableNumber,
  });

  bool get isDineIn => tableId != null;

  String get itemsSummary => items.map((i) => i.quantity > 1 ? '${i.name} x${i.quantity}' : i.name).join(', ');

  factory CafforaOrder.fromJson(Map<String, dynamic> json) {
    final tableJson = json['table'] as Map<String, dynamic>?;
    return CafforaOrder(
      id: json['id'] as int,
      orderNumber: json['orderNumber'] as String? ?? '',
      status: orderStatusFromString(json['status'] as String?),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      pickupFee: (json['pickupFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      tableId: json['tableId'] as int? ?? tableJson?['id'] as int?,
      tableNumber: json['tableNumber']?.toString() ?? tableJson?['tableNumber']?.toString(),
    );
  }

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'orderNumber': orderNumber,
        'status': orderStatusToApiString(status),
        'subtotal': subtotal,
        'pickupFee': pickupFee,
        'tax': tax,
        'total': total,
        'placedAt': placedAt.toIso8601String(),
        'itemsSummary': itemsSummary,
        'tableNumber': tableNumber,
      };

  factory CafforaOrder.fromDbRow(Map<String, dynamic> row) => CafforaOrder(
        id: row['id'] as int,
        orderNumber: row['orderNumber'] as String,
        status: orderStatusFromString(row['status'] as String?),
        subtotal: (row['subtotal'] as num).toDouble(),
        pickupFee: (row['pickupFee'] as num).toDouble(),
        tax: (row['tax'] as num).toDouble(),
        total: (row['total'] as num).toDouble(),
        placedAt: DateTime.tryParse(row['placedAt'] as String? ?? '') ?? DateTime.now(),
        tableNumber: row['tableNumber'] as String?,
        items: [
          OrderLineItem(
            productId: 0,
            name: row['itemsSummary'] as String? ?? 'Cached order',
            unitPrice: 0,
            quantity: 1,
          ),
        ],
      );
}
