class ReviewData {
  final int id;
  final int orderId;
  final int customerId;
  final int providerId;
  final int rating;
  final String? comment;
  final String? createdAt;
  final String? customerName;

  ReviewData({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.customerName,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];

    return ReviewData(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'],
      customerName: customer is Map<String, dynamic> ? customer['name'] : null,
    );
  }
}

class ReviewsResponse {
  final List<ReviewData> data;

  ReviewsResponse({required this.data});

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List items;
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map<String, dynamic>) {
      items = rawData['reviews'] as List? ?? [];
    } else {
      items = [];
    }
    return ReviewsResponse(
      data: items
          .map((item) => ReviewData.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
