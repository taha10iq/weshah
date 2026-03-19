// lib/data/repositories/customer_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final SupabaseClient _client;

  CustomerRepository(this._client);

  Future<List<CustomerModel>> getCustomers({
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('customers')
        .select('*, orders(count)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = _client
          .from('customers')
          .select('*, orders(count)')
          .or('full_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    final data = await query;
    return data
        .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> getCustomerById(String id) async {
    final data = await _client.from('customers').select().eq('id', id).single();
    return CustomerModel.fromJson(data);
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final data = await _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final data = await _client
        .from('customers')
        .update({
          ...customer.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', customer.id)
        .select()
        .single();
    return CustomerModel.fromJson(data);
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    late final List<dynamic> data;
    if (query.isEmpty) {
      data = await _client
          .from('customers')
          .select()
          .order('full_name')
          .limit(50);
    } else {
      data = await _client
          .from('customers')
          .select()
          .or('full_name.ilike.%$query%,phone.ilike.%$query%')
          .order('full_name')
          .limit(20);
    }
    return data
        .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
