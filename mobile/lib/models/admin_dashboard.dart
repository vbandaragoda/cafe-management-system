/// Mirrors the backend's GET /api/admin/dashboard response — a
/// cross-table aggregate computed server-side by joining orders,
/// order_items and products (today's gross sales, active order
/// counts, average prep time). Reflected verbatim in the Admin screen.
class AdminDashboard {
  final double todaysGrossSales;
  final int activeOrderCount;
  final int completedTodayCount;
  final double averagePrepMinutes;

  const AdminDashboard({
    required this.todaysGrossSales,
    required this.activeOrderCount,
    required this.completedTodayCount,
    required this.averagePrepMinutes,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      todaysGrossSales: (json['todaysGrossSales'] as num?)?.toDouble() ??
          (json['grossSalesToday'] as num?)?.toDouble() ??
          0.0,
      activeOrderCount: json['activeOrderCount'] as int? ?? 0,
      completedTodayCount: json['completedTodayCount'] as int? ?? 0,
      averagePrepMinutes: (json['averagePrepMinutes'] as num?)?.toDouble() ??
          (json['averagePrepTimeMinutes'] as num?)?.toDouble() ??
          0.0,
    );
  }
}
