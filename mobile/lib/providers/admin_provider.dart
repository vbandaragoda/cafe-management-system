import 'package:flutter/foundation.dart';
import '../models/admin_dashboard.dart';
import '../models/cafe_table.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/admin_service.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/table_service.dart';

/// Backs the Admin screen: product CRUD, categories/tables listings,
/// the live order queue, and the cross-table dashboard aggregate.
/// ADMIN-role gated in the UI layer (see AuthProvider.isAdmin) — this
/// provider assumes the caller is already authorized; the backend
/// re-checks the role on every call regardless, since client-side
/// gating is UX only, not security.
class AdminProvider extends ChangeNotifier {
  final ProductService _productService;
  final OrderService _orderService;
  final AdminService _adminService;
  final CategoryService _categoryService;
  final TableService _tableService;

  AdminProvider({
    ProductService? productService,
    OrderService? orderService,
    AdminService? adminService,
    CategoryService? categoryService,
    TableService? tableService,
  })  : _productService = productService ?? ProductService(),
        _orderService = orderService ?? OrderService(),
        _adminService = adminService ?? AdminService(),
        _categoryService = categoryService ?? CategoryService(),
        _tableService = tableService ?? TableService();

  List<Product> products = [];
  List<CafforaOrder> queue = [];
  List<Category> categories = [];
  List<CafeTable> tables = [];
  AdminDashboard? dashboard;
  bool isLoading = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _productService.fetchProducts(),
        _orderService.allOrders(activeOnly: true),
        _adminService.dashboard(),
        _categoryService.fetchAll(),
        _tableService.fetchAll(),
      ]);
      products = results[0] as List<Product>;
      queue = results[1] as List<CafforaOrder>;
      dashboard = results[2] as AdminDashboard;
      categories = results[3] as List<Category>;
      tables = results[4] as List<CafeTable>;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the Caffora server.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProduct(Product product, {required bool isNew}) async {
    try {
      final saved = isNew ? await _productService.createProduct(product) : await _productService.updateProduct(product);
      if (isNew) {
        products = [...products, saved];
      } else {
        products = products.map((m) => m.id == saved.id ? saved : m).toList();
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAvailability(Product product) async {
    try {
      final saved = await _productService.toggleAvailability(product.id);
      products = products.map((m) => m.id == saved.id ? saved : m).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      products = products.where((m) => m.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Called from a manual status button in the order queue.
  Future<CafforaOrder?> advanceOrderStatus(int orderId, OrderStatus status) async {
    try {
      final updated = await _orderService.updateStatus(orderId, status);
      queue = queue
          .map((o) => o.id == updated.id ? updated : o)
          .where((o) => o.status != OrderStatus.completed)
          .toList();
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }
}
