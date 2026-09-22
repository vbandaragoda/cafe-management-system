import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';
import '../services/local_db_service.dart';
import '../services/product_service.dart';

/// Data-view screen backing store (renamed from MenuProvider). Tries
/// the live backend first; on any network failure it silently falls
/// back to the last cached product catalog (sqflite) so the Menu
/// screen never goes blank offline — the "offline capability with
/// alternative content" requirement.
class ProductProvider extends ChangeNotifier {
  final ProductService _productService;
  final CategoryService _categoryService;
  final LocalDbService _localDb;

  ProductProvider({ProductService? productService, CategoryService? categoryService, LocalDbService? localDb})
      : _productService = productService ?? ProductService(),
        _categoryService = categoryService ?? CategoryService(),
        _localDb = localDb ?? LocalDbService.instance;

  List<Product> _items = [];
  List<Category> categories = [];
  bool isLoading = false;
  bool isShowingCachedData = false;
  String? error;
  int? selectedCategoryId;
  String searchTerm = '';

  List<Product> get items => _items;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final fetched = await _productService.fetchProducts(categoryId: selectedCategoryId, search: searchTerm);
      _items = fetched;
      isShowingCachedData = false;
      unawaited(_localDb.cacheProducts(fetched));
    } on NetworkUnavailableException {
      await _loadFromCache();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    // Best-effort: the real category list from the backend. If this
    // fails (e.g. offline), the chip row just falls back to "All" —
    // it never blocks the product list itself from loading.
    if (categories.isEmpty) {
      try {
        categories = await _categoryService.fetchAll();
      } catch (_) {
        // Ignored — see comment above.
      }
    }
  }

  Future<void> _loadFromCache() async {
    final cached = await _localDb.readCachedProducts();
    _items = cached;
    isShowingCachedData = true;
    if (cached.isEmpty) {
      error = 'No internet connection, and no cached menu is available yet.';
    }
  }

  void setCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearch(String term) {
    searchTerm = term;
    notifyListeners();
  }

  List<Product> get filtered {
    return _items.where((item) {
      final matchesCategory = selectedCategoryId == null || item.categoryId == selectedCategoryId;
      final matchesSearch = searchTerm.isEmpty || item.name.toLowerCase().contains(searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
