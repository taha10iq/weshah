// lib/data/models/customer_model.dart

import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? ordersCount;

  const CustomerModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.ordersCount,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      ordersCount: json['orders_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? ordersCount,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ordersCount: ordersCount ?? this.ordersCount,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, address, notes];
}
