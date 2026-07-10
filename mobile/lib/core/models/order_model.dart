class OrderData {
  final int id;
  final String orderCode;
  final String status;
  final int estimatedPrice;
  final int? finalPrice;
  final String address;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;
  final String? notes;
  final String? damageLevel;
  final String? damageDescription;
  final int? estimatedPriceMin;
  final int? estimatedPriceMax;
  final String? queueNote;
  final String scheduleAt;
  final List<PaymentData> payments;
  final String? finalPriceApprovalStatus;

  OrderData({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.estimatedPrice,
    this.finalPrice,
    required this.address,
    this.customerLatitude,
    this.customerLongitude,
    this.providerLatitude,
    this.providerLongitude,
    this.notes,
    this.damageLevel,
    this.damageDescription,
    this.estimatedPriceMin,
    this.estimatedPriceMax,
    this.queueNote,
    required this.scheduleAt,
    required this.payments,
    this.finalPriceApprovalStatus,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'] ?? 0,
      orderCode: json['order_code'] ?? '',
      status: json['status'] ?? 'CREATED',
      estimatedPrice: json['estimated_price'] ?? 0,
      finalPrice: json['final_price'],
      address: json['address'] ?? '',
      customerLatitude: double.tryParse(json['customer_latitude']?.toString() ?? ''),
      customerLongitude: double.tryParse(json['customer_longitude']?.toString() ?? ''),
      providerLatitude: double.tryParse(json['provider_latitude']?.toString() ?? ''),
      providerLongitude: double.tryParse(json['provider_longitude']?.toString() ?? ''),
      notes: json['notes'],
      damageLevel: json['damage_level'],
      damageDescription: json['damage_description'],
      estimatedPriceMin: json['estimated_price_min'],
      estimatedPriceMax: json['estimated_price_max'],
      queueNote: json['queue_note'],
      scheduleAt: json['schedule_at'] ?? '',
      payments:
          (json['payments'] as List?)
              ?.map((item) => PaymentData.fromJson(item))
              .toList() ??
          [],
      finalPriceApprovalStatus: json['final_price_approval'] is Map
          ? json['final_price_approval']['approval_status']?.toString()
          : null,
    );
  }
}

class PaymentData {
  final int id;
  final String paymentType;
  final int amount;
  final String status;
  final String? externalPaymentId;
  final String? paidAt;
  final String? checkoutUrl;

  PaymentData({
    required this.id,
    required this.paymentType,
    required this.amount,
    required this.status,
    this.externalPaymentId,
    this.paidAt,
    this.checkoutUrl,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'] ?? 0,
      paymentType: json['payment_type'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'UNPAID',
      externalPaymentId: json['external_payment_id'],
      paidAt: json['paid_at'],
      checkoutUrl: json['checkout_url'],
    );
  }
}

class OrdersResponse {
  final List<OrderData> data;

  OrdersResponse({required this.data});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      data:
          (json['data'] as List?)
              ?.map((item) => OrderData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class CreateOrderRequest {
  final int providerId;
  final int? categoryId;
  final int? providerServiceId;
  final int kotaId;
  final int kecamatanId;
  final String scheduleAt;
  final String address;
  final String? notes;
  final String? damageLevel;
  final String? damageDescription;
  final int? estimatedPriceMin;
  final int? estimatedPriceMax;
  final int? estimatedPrice;
  final List<String>? attachmentUrls;
  final List<String>? attachmentPaths;

  CreateOrderRequest({
    required this.providerId,
    this.categoryId,
    this.providerServiceId,
    required this.kotaId,
    required this.kecamatanId,
    required this.scheduleAt,
    required this.address,
    this.notes,
    this.damageLevel,
    this.damageDescription,
    this.estimatedPriceMin,
    this.estimatedPriceMax,
    this.estimatedPrice,
    this.attachmentUrls,
    this.attachmentPaths,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'provider_id': providerId,
      'kota_id': kotaId,
      'kecamatan_id': kecamatanId,
      'schedule_at': scheduleAt,
      'address': address,
    };

    if (categoryId != null) {
      data['category_id'] = categoryId!;
    }
    if (providerServiceId != null) {
      data['provider_service_id'] = providerServiceId!;
    }
    if (notes != null) {
      data['notes'] = notes!;
    }
    if (damageLevel != null) {
      data['damage_level'] = damageLevel!;
    }
    if (damageDescription != null) {
      data['damage_description'] = damageDescription!;
    }
    if (estimatedPriceMin != null) {
      data['estimated_price_min'] = estimatedPriceMin!;
    }
    if (estimatedPriceMax != null) {
      data['estimated_price_max'] = estimatedPriceMax!;
    }
    if (estimatedPrice != null) {
      data['estimated_price'] = estimatedPrice!;
    }
    if (attachmentUrls != null && attachmentUrls!.isNotEmpty) {
      data['attachment_urls'] = attachmentUrls;
    }

    return data;
  }
}
