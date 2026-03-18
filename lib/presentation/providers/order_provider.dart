// lib/presentation/providers/order_provider.dart

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_detail_model.dart';
import '../../data/models/order_attachment_model.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/datasources/storage_datasource.dart';
import 'supabase_provider.dart';

// Filters state
class OrderFilterState {
  final String searchQuery;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? customerId;

  const OrderFilterState({
    this.searchQuery = '',
    this.status,
    this.dateFrom,
    this.dateTo,
    this.customerId,
  });

  OrderFilterState copyWith({
    String? searchQuery,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? customerId,
    bool clearStatus = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearCustomerId = false,
  }) {
    return OrderFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
    );
  }
}

class OrderFilterNotifier extends StateNotifier<OrderFilterState> {
  OrderFilterNotifier() : super(const OrderFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setStatus(String? s) => state = s == null
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: s);
  void setDateFrom(DateTime? d) => state = d == null
      ? state.copyWith(clearDateFrom: true)
      : state.copyWith(dateFrom: d);
  void setDateTo(DateTime? d) => state = d == null
      ? state.copyWith(clearDateTo: true)
      : state.copyWith(dateTo: d);
  void setCustomerId(String? id) => state = id == null
      ? state.copyWith(clearCustomerId: true)
      : state.copyWith(customerId: id);
  void clearAll() => state = const OrderFilterState();
}

final orderFilterProvider =
    StateNotifierProvider<OrderFilterNotifier, OrderFilterState>(
      (ref) => OrderFilterNotifier(),
    );

// Orders list
final ordersListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final filters = ref.watch(orderFilterProvider);
  final repo = ref.read(orderRepositoryProvider);
  return repo.getOrders(
    searchQuery: filters.searchQuery.isEmpty ? null : filters.searchQuery,
    status: filters.status,
    dateFrom: filters.dateFrom,
    dateTo: filters.dateTo,
    customerId: filters.customerId,
  );
});

// Orders by customer
final ordersByCustomerProvider =
    FutureProvider.family<List<OrderModel>, String>((ref, customerId) async {
      final repo = ref.read(orderRepositoryProvider);
      return repo.getOrders(customerId: customerId);
    });

// Single order
final orderByIdProvider = FutureProvider.family<OrderModel, String>((
  ref,
  id,
) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getOrderById(id);
});

// Dashboard stats
final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getDashboardStats();
});

// Order CRUD notifier
class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repo;
  final StorageDataSource _storage;
  final Ref _ref;

  OrderNotifier(this._repo, this._storage, this._ref)
    : super(const AsyncValue.data(null));

  Future<OrderModel?> createOrder(
    OrderModel order, {
    OrderDetailModel? details,
  }) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repo.createOrder(order);
      if (details != null) {
        await _repo.upsertOrderDetail(details.copyWith(orderId: created.id));
      }
      state = const AsyncValue.data(null);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(ordersByCustomerProvider(created.customerId));
      _ref.invalidate(dashboardStatsProvider);
      return created;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<bool> updateOrder(
    OrderModel order, {
    OrderDetailModel? details,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateOrder(order);
      if (details != null) {
        await _repo.upsertOrderDetail(details);
      }
      state = const AsyncValue.data(null);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(orderByIdProvider(order.id));
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> updateStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateOrderStatus(orderId, status, note: note);
      state = const AsyncValue.data(null);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(orderByIdProvider(orderId));
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteOrder(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<OrderAttachmentModel?> uploadAttachment({
    required String orderId,
    required String fileName,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _storage.uploadFile(
        orderId: orderId,
        fileName: fileName,
        fileBytes: Uint8List.fromList(fileBytes),
        contentType: contentType,
      );
      final attachment = await _repo.addAttachment(
        OrderAttachmentModel(
          id: '',
          orderId: orderId,
          fileName: fileName,
          filePath: result['file_path']!,
          fileUrl: result['file_url'],
          fileType: contentType,
          uploadedAt: DateTime.now(),
        ),
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(orderByIdProvider(orderId));
      return attachment;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<bool> deleteAttachment(
    String attachmentId,
    String filePath,
    String orderId,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _storage.deleteFile(filePath);
      await _repo.deleteAttachment(attachmentId);
      state = const AsyncValue.data(null);
      _ref.invalidate(orderByIdProvider(orderId));
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<void>>((ref) {
      return OrderNotifier(
        ref.read(orderRepositoryProvider),
        ref.read(storageDataSourceProvider),
        ref,
      );
    });
