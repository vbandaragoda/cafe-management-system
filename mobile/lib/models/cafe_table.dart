/// Mirrors the backend's `Table` resource. `tableNumber` is kept as a
/// String (not int) since a physical table's printed number/code could
/// be alphanumeric (e.g. "12A", "Patio-3") — the backend and the QR
/// payload (`cafe://table/{tableNumber}`) both treat it as a label.
class CafeTable {
  final int id;
  final String tableNumber;

  const CafeTable({
    required this.id,
    required this.tableNumber,
  });

  factory CafeTable.fromJson(Map<String, dynamic> json) {
    return CafeTable(
      id: json['id'] as int,
      tableNumber: json['tableNumber']?.toString() ?? '',
    );
  }
}
