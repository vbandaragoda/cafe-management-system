import '../models/payment.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Wraps /api/payments on the Caffora backend. IMPORTANT: this is a
/// SIMULATED payment flow — there is no real payment gateway
/// integration anywhere in this app. The backend marks the payment
/// PAID immediately on `recordPayment`; nothing here ever charges a
/// real card or wallet. Every caller that surfaces a [Payment] to the
/// user must say so in its copy.
class PaymentService {
  final ApiClient _client;
  PaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Payment> recordPayment(int orderId, PaymentMethod method) async {
    final json = await _client.post('/payments', body: {
      'orderId': orderId,
      'method': paymentMethodToApiString(method),
    }) as Map<String, dynamic>;
    return Payment.fromJson(json);
  }

  /// Returns null if no payment has been recorded for this order yet.
  Future<Payment?> byOrder(int orderId) async {
    try {
      final json = await _client.get('/payments/order/$orderId') as Map<String, dynamic>?;
      if (json == null) return null;
      return Payment.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
