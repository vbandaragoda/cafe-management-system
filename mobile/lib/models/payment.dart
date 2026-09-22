enum PaymentMethod { cash, card, mobileWallet }

PaymentMethod paymentMethodFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'CASH':
      return PaymentMethod.cash;
    case 'MOBILE_WALLET':
      return PaymentMethod.mobileWallet;
    default:
      return PaymentMethod.card;
  }
}

String paymentMethodToApiString(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'CASH';
    case PaymentMethod.card:
      return 'CARD';
    case PaymentMethod.mobileWallet:
      return 'MOBILE_WALLET';
  }
}

String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.mobileWallet:
      return 'Mobile Wallet';
  }
}

/// Mirrors the backend's `POST /api/payments` response. This whole
/// feature is SIMULATED — there is no real payment gateway wired up
/// anywhere in this app or the backend; the server marks the payment
/// PAID immediately. Every screen that shows a [Payment] must make
/// that clear in its copy rather than implying a real charge occurred.
class Payment {
  final int id;
  final int orderId;
  final double amount;
  final PaymentMethod method;
  final String status;
  final DateTime paidAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: paymentMethodFromString(json['method'] as String?),
      status: json['status'] as String? ?? 'PAID',
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
