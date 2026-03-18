// lib/data/repositories/order_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/order_detail_model.dart';
import '../models/order_attachment_model.dart';
import '../models/dashboard_stats_model.dart';

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  static const _orderSelect = '''
    *,
    customers(id, full_name, phone),
    order_details(*),
    order_attachments(*)
  ''';

  Future<List<OrderModel>> getOrders({
    String? searchQuery,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('orders')
        .select(_orderSelect)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (customerId != null) {
      query = _client
          .from('orders')
          .select(_orderSelect)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    } else if (status != null && status.isNotEmpty) {
      query = _client
          .from('orders')
          .select(_orderSelect)
          .eq('status', status)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    final data = await query;
    var orders = data
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      orders = orders.where((o) {
        return (o.customerName?.toLowerCase().contains(q) ?? false) ||
            (o.customerPhone?.contains(q) ?? false) ||
            o.orderNumber.toString().contains(q);
      }).toList();
    }

    return orders;
  }

  Future<OrderModel> getOrderById(String id) async {
    final data = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('id', id)
        .single();
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    final data = await _client
        .from('orders')
        .insert(order.toJson())
        .select(_orderSelect)
        .single();
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> updateOrder(OrderModel order) async {
    final data = await _client
        .from('orders')
        .update({
          ...order.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', order.id)
        .select(_orderSelect)
        .single();
    return OrderModel.fromJson(data);
  }

  Future<void> deleteOrder(String id) async {
    await _client.from('orders').delete().eq('id', id);
  }

  Future<OrderDetailModel> upsertOrderDetail(OrderDetailModel detail) async {
    final existing = await _client
        .from('order_details')
        .select()
        .eq('order_id', detail.orderId)
        .maybeSingle();

    if (existing != null) {
      final data = await _client
          .from('order_details')
          .update({
            ...detail.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', detail.orderId)
          .select()
          .single();
      return OrderDetailModel.fromJson(data);
    } else {
      final data = await _client
          .from('order_details')
          .insert(detail.toJson())
          .select()
          .single();
      return OrderDetailModel.fromJson(data);
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? note,
  }) async {
    final order = await getOrderById(orderId);
    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'old_status': order.status,
      'new_status': newStatus,
      if (note != null) 'note': note,
    });
    await _client
        .from('orders')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  Future<OrderAttachmentModel> addAttachment(
    OrderAttachmentModel attachment,
  ) async {
    final data = await _client
        .from('order_attachments')
        .insert(attachment.toJson())
        .select()
        .single();
    return OrderAttachmentModel.fromJson(data);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await _client.from('order_attachments').delete().eq('id', attachmentId);
  }

  Future<DashboardStatsModel> getDashboardStats() async {
    final customersList = await _client.from('customers').select('id');
    final customersCount = customersList.length;

    final ordersData = await _client
        .from('orders')
        .select('status, total_price, amount_paid, remaining_amount');

    int totalOrders = 0;
    int newOrders = 0;
    int inProgressOrders = 0;
    int readyOrders = 0;
    int deliveredOrders = 0;
    int cancelledOrders = 0;
    double totalRevenue = 0;
    double totalPaid = 0;
    double totalRemaining = 0;

    for (final o in ordersData) {
      totalOrders++;
      final status = o['status'] as String;
      switch (status) {
        case 'new':
          newOrders++;
          break;
        case 'in_progress':
          inProgressOrders++;
          break;
        case 'ready':
          readyOrders++;
          break;
        case 'delivered':
          deliveredOrders++;
          break;
        case 'cancelled':
          cancelledOrders++;
          break;
      }
      totalRevenue += (o['total_price'] as num).toDouble();
      totalPaid += (o['amount_paid'] as num).toDouble();
      totalRemaining += (o['remaining_amount'] as num? ?? 0).toDouble();
    }

    return DashboardStatsModel(
      totalCustomers: customersCount,
      totalOrders: totalOrders,
      newOrders: newOrders,
      inProgressOrders: inProgressOrders,
      readyOrders: readyOrders,
      deliveredOrders: deliveredOrders,
      cancelledOrders: cancelledOrders,
      totalRevenue: totalRevenue,
      totalPaid: totalPaid,
      totalRemaining: totalRemaining,
    );
  }
}
