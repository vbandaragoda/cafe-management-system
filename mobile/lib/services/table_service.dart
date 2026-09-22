import '../models/cafe_table.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Wraps /api/tables on the Caffora backend — the core of the
/// table-QR ordering flow. `lookupByCode` is PUBLIC (no auth), since a
/// customer may scan a table before signing in; it's used both for a
/// real camera scan (the raw `cafe://table/{tableNumber}` payload) and
/// for the manual-entry fallback (`TableScanScreen` builds the same
/// `cafe://table/$typedNumber` string and passes it through here
/// unchanged, so both paths hit the exact same backend contract).
class TableService {
  final ApiClient _client;
  TableService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<CafeTable> lookupByCode(String code) async {
    try {
      final json = await _client.get('/tables/lookup', query: {'code': code}, auth: false) as Map<String, dynamic>;
      return CafeTable.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw ApiException(statusCode: 404, message: 'That table QR code wasn\'t recognized. Double-check the code and try again.');
      }
      rethrow;
    }
  }

  /// ADMIN only — backs AdminTablesScreen's printable QR list.
  Future<List<CafeTable>> fetchAll() async {
    final json = await _client.get('/tables');
    final list = (json as List<dynamic>? ?? []);
    return list.map((e) => CafeTable.fromJson(e as Map<String, dynamic>)).toList();
  }
}
