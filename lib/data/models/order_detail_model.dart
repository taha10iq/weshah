// lib/data/models/order_detail_model.dart

import 'package:equatable/equatable.dart';

class OrderDetailModel extends Equatable {
  final String id;
  final String orderId;
  final String? sleeveStyle;
  final bool addAmericanCap;
  final double? shoulderWidthCm;
  final double? robeLengthCm;
  final double? sleeveLengthCm;
  final double? headCircumferenceCm;
  final String? robeColor;
  final String? embroideryColor;
  final String? capColor;
  final String? capText;
  final String? rightSideText;
  final String? leftSideText;
  final String? chestText;
  final String? sashText;
  final String? graduationYear;
  final int quantity;
  final double unitPrice;
  final double? lineTotal;
  final String? designNotes;
  final String? customModelNote;
  // URLs صور النصوص
  final String? rightTextImageUrl;
  final String? leftTextImageUrl;
  final String? chestTextImageUrl;
  final String? sashTextImageUrl;
  final String? capTextImageUrl;
  final String? designNotesImageUrl;

  const OrderDetailModel({
    required this.id,
    required this.orderId,
    this.sleeveStyle,
    this.addAmericanCap = false,
    this.shoulderWidthCm,
    this.robeLengthCm,
    this.sleeveLengthCm,
    this.headCircumferenceCm,
    this.robeColor,
    this.embroideryColor,
    this.capColor,
    this.capText,
    this.rightSideText,
    this.leftSideText,
    this.chestText,
    this.sashText,
    this.graduationYear,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lineTotal,
    this.designNotes,
    this.customModelNote,
    this.rightTextImageUrl,
    this.leftTextImageUrl,
    this.chestTextImageUrl,
    this.sashTextImageUrl,
    this.capTextImageUrl,
    this.designNotesImageUrl,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      sleeveStyle: json['sleeve_style'] as String?,
      addAmericanCap: json['add_american_cap'] as bool? ?? false,
      shoulderWidthCm: (json['shoulder_width_cm'] as num?)?.toDouble(),
      robeLengthCm: (json['robe_length_cm'] as num?)?.toDouble(),
      sleeveLengthCm: (json['sleeve_length_cm'] as num?)?.toDouble(),
      headCircumferenceCm: (json['head_circumference_cm'] as num?)?.toDouble(),
      robeColor: json['robe_color'] as String?,
      embroideryColor: json['embroidery_color'] as String?,
      capColor: json['cap_color'] as String?,
      capText: json['cap_text'] as String?,
      rightSideText: json['right_side_text'] as String?,
      leftSideText: json['left_side_text'] as String?,
      chestText: json['chest_text'] as String?,
      sashText: json['sash_text'] as String?,
      graduationYear: json['graduation_year'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      designNotes: json['design_notes'] as String?,
      customModelNote: json['custom_model_note'] as String?,
      rightTextImageUrl: json['right_text_image_url'] as String?,
      leftTextImageUrl: json['left_text_image_url'] as String?,
      chestTextImageUrl: json['chest_text_image_url'] as String?,
      sashTextImageUrl: json['sash_text_image_url'] as String?,
      capTextImageUrl: json['cap_text_image_url'] as String?,
      designNotesImageUrl: json['design_notes_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      if (sleeveStyle != null) 'sleeve_style': sleeveStyle,
      'add_american_cap': addAmericanCap,
      if (shoulderWidthCm != null) 'shoulder_width_cm': shoulderWidthCm,
      if (robeLengthCm != null) 'robe_length_cm': robeLengthCm,
      if (sleeveLengthCm != null) 'sleeve_length_cm': sleeveLengthCm,
      if (headCircumferenceCm != null)
        'head_circumference_cm': headCircumferenceCm,
      if (robeColor != null) 'robe_color': robeColor,
      if (embroideryColor != null) 'embroidery_color': embroideryColor,
      if (capColor != null) 'cap_color': capColor,
      if (capText != null) 'cap_text': capText,
      if (rightSideText != null) 'right_side_text': rightSideText,
      if (leftSideText != null) 'left_side_text': leftSideText,
      if (chestText != null) 'chest_text': chestText,
      if (sashText != null) 'sash_text': sashText,
      if (graduationYear != null) 'graduation_year': graduationYear,
      'quantity': quantity,
      'unit_price': unitPrice,
      if (designNotes != null) 'design_notes': designNotes,
      if (customModelNote != null) 'custom_model_note': customModelNote,
      if (rightTextImageUrl != null) 'right_text_image_url': rightTextImageUrl,
      if (leftTextImageUrl != null) 'left_text_image_url': leftTextImageUrl,
      if (chestTextImageUrl != null) 'chest_text_image_url': chestTextImageUrl,
      if (sashTextImageUrl != null) 'sash_text_image_url': sashTextImageUrl,
      if (capTextImageUrl != null) 'cap_text_image_url': capTextImageUrl,
      if (designNotesImageUrl != null) 'design_notes_image_url': designNotesImageUrl,
    };
  }

  OrderDetailModel copyWith({
    String? id,
    String? orderId,
    String? sleeveStyle,
    bool? addAmericanCap,
    double? shoulderWidthCm,
    double? robeLengthCm,
    double? sleeveLengthCm,
    double? headCircumferenceCm,
    String? robeColor,
    String? embroideryColor,
    String? capColor,
    String? capText,
    String? rightSideText,
    String? leftSideText,
    String? chestText,
    String? sashText,
    String? graduationYear,
    int? quantity,
    double? unitPrice,
    double? lineTotal,
    String? designNotes,
    String? customModelNote,
    String? rightTextImageUrl,
    String? leftTextImageUrl,
    String? chestTextImageUrl,
    String? sashTextImageUrl,
    String? capTextImageUrl,
    String? designNotesImageUrl,
  }) {
    return OrderDetailModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      sleeveStyle: sleeveStyle ?? this.sleeveStyle,
      addAmericanCap: addAmericanCap ?? this.addAmericanCap,
      shoulderWidthCm: shoulderWidthCm ?? this.shoulderWidthCm,
      robeLengthCm: robeLengthCm ?? this.robeLengthCm,
      sleeveLengthCm: sleeveLengthCm ?? this.sleeveLengthCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      robeColor: robeColor ?? this.robeColor,
      embroideryColor: embroideryColor ?? this.embroideryColor,
      capColor: capColor ?? this.capColor,
      capText: capText ?? this.capText,
      rightSideText: rightSideText ?? this.rightSideText,
      leftSideText: leftSideText ?? this.leftSideText,
      chestText: chestText ?? this.chestText,
      sashText: sashText ?? this.sashText,
      graduationYear: graduationYear ?? this.graduationYear,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      designNotes: designNotes ?? this.designNotes,
      customModelNote: customModelNote ?? this.customModelNote,
      rightTextImageUrl: rightTextImageUrl ?? this.rightTextImageUrl,
      leftTextImageUrl: leftTextImageUrl ?? this.leftTextImageUrl,
      chestTextImageUrl: chestTextImageUrl ?? this.chestTextImageUrl,
      sashTextImageUrl: sashTextImageUrl ?? this.sashTextImageUrl,
      capTextImageUrl: capTextImageUrl ?? this.capTextImageUrl,
      designNotesImageUrl: designNotesImageUrl ?? this.designNotesImageUrl,
    );
  }

  @override
  List<Object?> get props => [id, orderId, sleeveStyle, quantity, unitPrice];
}
