import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/api_exception.dart';
import '../services/local_db_service.dart';
import '../services/order_service.dart';

/// Backs the "My Orders" data-view screen. Polls the backend on a
/// timer so that a status change an admin makes on their device shows
/// up here automatically within a few seconds, without the customer
/// needing to manually refresh — this is the assignment's "update by
/// one user reflected in another user's view" requirement in action.
/// Falls back to the sqflite cache when offline.
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;
  final LocalDbService _localDb;
  Timer? _pollTimer;

  OrderProvider({OrderService? orderService, LocalDbService? localDb})
      : _orderService = orderService ?? OrderService(),
        _localDb = localDb ?? LocalDbService.instance;

  List<CafforaOrder> _orders = [];
  bool isLoading = false;
  bool isShowingCachedData = false;
  String? error;
  CafforaOrder? lastPlacedOrder;

  List<CafforaOrder> get orders => _orders;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final fetched = await _orderService.myOrders();
      _orders = fetched;
      isShowingCachedData = false;
      error = null;
      unawaited(_localDb.cacheOrders(fetched));
    } on NetworkUnavailableException {
      final cached = await _localDb.readCachedOrders();
      _orders = cached;
      isShowingCachedData = true;
      if (cached.isEmpty) error = 'No internet connection, and no cached orders yet.';
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => load(silent: true));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// [tableId] comes from the currently-scanned table (TableProvider);
  /// null places a plain pickup order.
  Future<CafforaOrder?> placeOrder(List<CartItem> cartItems, {int? tableId, String pickupType = 'COUNTER'}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final order = await _orderService.placeOrder(cartItems, tableId: tableId, pickupType: pickupType);
      lastPlacedOrder = order;
      _orders = [order, ..._orders];
      return order;
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } on NetworkUnavailableException catch (e) {
      error = e.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
