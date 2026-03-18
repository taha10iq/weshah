// lib/data/models/order_model.dart

import 'package:equatable/equatable.dart';
import 'order_detail_model.dart';
import 'order_attachment_model.dart';

class OrderModel extends Equatable {
  final String id;
  final int orderNumber;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime orderDate;
  final String status;
  final double totalPrice;
  final double amountPaid;
  final double remainingAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderDetailModel? details;
  final List<OrderAttachmentModel> attachments;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.orderDate,
    required this.status,
    required this.totalPrice,
    required this.amountPaid,
    required this.remainingAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.details,
    this.attachments = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['id'] as String,
      orderNumber: (json['order_number'] as num).toInt(),
      customerId: json['customer_id'] as String,
      customerName: customer?['full_name'] as String?,
      customerPhone: customer?['phone'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      remainingAmount:
          (json['remaining_amount'] as num?)?.toDouble() ??
          ((json['total_price'] as num).toDouble() -
              (json['amount_paid'] as num).toDouble()),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      details: _parseOrderDetails(json['order_details']),
      attachments:
          (json['order_attachments'] as List<dynamic>?)
              ?.map(
                (e) => OrderAttachmentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'status': status,
      'total_price': totalPrice,
      'amount_paid': amountPaid,
      if (notes != null) 'notes': notes,
    };
  }

  // Supabase returns order_details as a List (one-to-one join still comes as List)
  static OrderDetailModel? _parseOrderDetails(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return OrderDetailModel.fromJson(raw);
    if (raw is List && raw.isNotEmpty) {
      return OrderDetailModel.fromJson(raw.first as Map<String, dynamic>);
    }
    return null;
  }

  OrderModel copyWith({
    String? id,
    int? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? orderDate,
    String? status,
    double? totalPrice,
    double? amountPaid,
    double? remainingAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderDetailModel? details,
    List<OrderAttachmentModel>? attachments,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      details: details ?? this.details,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerId,
    status,
    totalPrice,
    amountPaid,
  ];
}
