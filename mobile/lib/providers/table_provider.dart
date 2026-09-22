import 'package:flutter/foundation.dart';
import '../models/cafe_table.dart';

/// Holds the currently-scanned/selected table for the active ordering
/// session. Null means a plain pickup order; non-null means dine-in at
/// that table. Set by TableScanScreen after a successful
/// `TableService.lookupByCode`, read by CartScreen when placing the
/// order, and cleared when the customer explicitly switches back to
/// pickup.
class TableProvider extends ChangeNotifier {
  CafeTable? _table;

  CafeTable? get currentTable => _table;
  bool get hasTable => _table != null;

  void setTable(CafeTable table) {
    _table = table;
    notifyListeners();
  }

  void clearTable() {
    _table = null;
    notifyListeners();
  }
}
