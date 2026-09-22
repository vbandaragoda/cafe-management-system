import '../models/category.dart';
import 'api_client.dart';

/// Wraps /api/categories on the Caffora backend. Public endpoint — no
/// dedicated create/edit endpoint is exposed to mobile yet, so this is
/// read-only (see AdminCategoriesScreen).
class CategoryService {
  final ApiClient _client;
  CategoryService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Category>> fetchAll() async {
    final json = await _client.get('/categories', auth: false);
    final list = (json as List<dynamic>? ?? []);
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}
