// lib/presentation/providers/customer_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'supabase_provider.dart';

// Search query notifier
class CustomerSearchNotifier extends StateNotifier<String> {
  CustomerSearchNotifier() : super('');

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final customerSearchProvider =
    StateNotifierProvider<CustomerSearchNotifier, String>(
      (ref) => CustomerSearchNotifier(),
    );

// Customers list provider
final customersProvider = FutureProvider.family<List<CustomerModel>, String>((
  ref,
  query,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getCustomers(searchQuery: query.isEmpty ? null : query);
});

// All customers (watches search query)
final customersListProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final search = ref.watch(customerSearchProvider);
  final repo = ref.read(customerRepositoryProvider);
  return repo.getCustomers(searchQuery: search.isEmpty ? null : search);
});

// Single customer provider
final customerByIdProvider = FutureProvider.family<CustomerModel, String>((
  ref,
  id,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getCustomerById(id);
});

// Customer orders count
final customerOrdersCountProvider = FutureProvider.family<int, String>((
  ref,
  customerId,
) async {
  // Will be populated when fetching orders
  return 0;
});

// Customer CRUD operations
class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repo;
  final Ref _ref;

  CustomerNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<CustomerModel?> createCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createCustomer(customer);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      return result;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCustomer(customer);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(customerByIdProvider(customer.id));
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCustomer(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final customerNotifierProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
      return CustomerNotifier(ref.read(customerRepositoryProvider), ref);
    });
