// lib/data/models/dashboard_stats_model.dart

class DashboardStatsModel {
  final int totalCustomers;
  final int totalOrders;
  final int newOrders;
  final int inProgressOrders;
  final int readyOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double totalPaid;
  final double totalRemaining;

  const DashboardStatsModel({
    this.totalCustomers = 0,
    this.totalOrders = 0,
    this.newOrders = 0,
    this.inProgressOrders = 0,
    this.readyOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.totalRevenue = 0,
    this.totalPaid = 0,
    this.totalRemaining = 0,
  });
}
