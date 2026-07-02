import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_response.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../http/dio_provider.dart';

class ApiService {
  final Dio dio;

  ApiService({required this.dio});

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }

  // ===== AUTH ENDPOINTS =====

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    int? categoryId,
    String? businessName,
    String? serviceName,
    int? basePrice,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': role,
      };

      if (role == 'PROVIDER') {
        if (categoryId != null) data['category_id'] = categoryId;
        if (businessName != null) data['business_name'] = businessName;
        if (serviceName != null) data['service_name'] = serviceName;
        if (basePrice != null) data['base_price'] = basePrice;
      }

      final response = await dio.post('/api/auth/register', data: data);
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.token != null) {
        setToken(authResponse.token!);
      }
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('/api/auth/logout');
      clearToken();
    } catch (e) {
      rethrow;
    }
  }

  // ===== SESSION-BASED AUTH (SPA) =====

  Future<Map<String, dynamic>> sessionLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/api/auth/session-login',
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sessionLogout() async {
    try {
      await dio.post('/api/auth/session-logout');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    try {
      final response = await dio.get('/api/user-session');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ===== CATALOG ENDPOINTS =====

  Future<CategoriesResponse> getCategories() async {
    try {
      final response = await dio.get('/api/catalog/categories');
      return CategoriesResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProvidersResponse> getProvidersByCategory(int categoryId) async {
    try {
      final response = await dio.get(
        '/api/catalog/categories/$categoryId/providers',
      );
      return ProvidersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProviderProfile> getProviderDetail(int providerId) async {
    try {
      final response = await dio.get('/api/catalog/providers/$providerId');
      final data = response.data['data'];
      if (data is Map<String, dynamic> && data.containsKey('provider')) {
        return ProviderProfile.fromJson(
          Map<String, dynamic>.from(data['provider']),
        );
      }
      return ProviderProfile.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<ProvidersResponse> searchProviders(String query) async {
    try {
      final response = await dio.get(
        '/api/catalog/providers/search',
        queryParameters: {'q': query},
      );
      return ProvidersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ===== ORDER ENDPOINTS =====

  Future<OrderData> createOrder(CreateOrderRequest request) async {
    try {
      final response = await dio.post('/api/orders', data: request.toJson());
      return OrderData.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrdersResponse> getMyOrders() async {
    try {
      final response = await dio.get('/api/orders/my-orders');
      return OrdersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderData> getOrderDetail(int orderId) async {
    try {
      final response = await dio.get('/api/orders/$orderId');
      return OrderData.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? photoPath,
    MultipartFile? photoFile,
  }) async {
    try {
      final form = FormData();
      if (fullName != null) {
        form.fields.add(MapEntry('full_name', fullName));
      }
      if (phoneNumber != null) {
        form.fields.add(MapEntry('phone_number', phoneNumber));
      }
      if (photoFile != null) {
        form.files.add(MapEntry('profile_photo', photoFile));
      }

      final response = await dio.post('/api/profile/update', data: form);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final response = await dio.delete('/api/profile/photo');
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendChatbotMessage(String message) async {
    try {
      final response = await dio.post(
        '/api/chatbot/send',
        data: {'message': message},
      );
      final data = response.data;
      if (data is Map &&
          data['data'] != null &&
          data['data']['reply'] != null) {
        return data['data']['reply'].toString();
      }
      return data.toString();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToOrder({
    required int orderId,
    required String action,
  }) async {
    try {
      await dio.post('/api/orders/$orderId/respond', data: {'action': action});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startWork(int orderId) async {
    try {
      await dio.post('/api/orders/$orderId/start-work');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeOrder({
    required int orderId,
    required int finalPrice,
  }) async {
    try {
      await dio.post(
        '/api/orders/$orderId/complete',
        data: {'final_price': finalPrice},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder({required int orderId, String? reason}) async {
    try {
      await dio.post(
        '/api/orders/$orderId/cancel',
        data: {'reason': reason ?? 'Dibatalkan oleh customer'},
      );
    } catch (e) {
      rethrow;
    }
  }

  // ===== PAYMENT ENDPOINTS =====

  Future<Map<String, dynamic>> generateQRIS(int paymentId) async {
    try {
      final response = await dio.post('/api/payments/$paymentId/generate-qris');
      final rawData = response.data['data'];
      Map<String, dynamic> data;
      if (rawData is Map<String, dynamic> && rawData.containsKey('qris')) {
        data = Map<String, dynamic>.from(rawData['qris']);
      } else {
        data = Map<String, dynamic>.from(rawData ?? {});
      }
      final checkoutUrl = data['checkout_url'];
      if (checkoutUrl != null) {
        data['checkout_url'] = checkoutUrl.toString();
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmPayment(int paymentId) async {
    try {
      final response = await dio.post('/api/payments/$paymentId/confirm');
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentData> getPaymentStatus(int paymentId) async {
    try {
      final response = await dio.get('/api/payments/$paymentId');
      final data = response.data['data'];
      if (data is Map<String, dynamic> && data.containsKey('payment')) {
        return PaymentData.fromJson(Map<String, dynamic>.from(data['payment']));
      }
      return PaymentData.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      rethrow;
    }
  }

  // ===== REVIEW ENDPOINTS =====

  Future<void> createReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      await dio.post(
        '/api/orders/$orderId/review',
        data: {'rating': rating, 'comment': comment},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ReviewsResponse> getProviderReviews(int providerId) async {
    try {
      final response = await dio.get(
        '/api/catalog/providers/$providerId/reviews',
      );
      return ReviewsResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ReviewData?> getOrderReview(int orderId) async {
    try {
      final response = await dio.get('/api/reviews/$orderId');
      return ReviewData.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );
    } catch (e) {
      return null;
    }
  }

  // ===== ADMIN ENDPOINTS =====

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await dio.get('/api/admin/dashboard');
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<ProvidersResponse> getPendingProviders() async {
    try {
      final response = await dio.get('/api/admin/providers/pending');
      return ProvidersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProvidersResponse> getAllProviders({bool? isVerified}) async {
    try {
      final params = <String, dynamic>{};
      if (isVerified != null) params['is_verified'] = isVerified;
      final response = await dio.get(
        '/api/admin/providers',
        queryParameters: params,
      );
      return ProvidersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProviderVerification({
    required int providerId,
    required bool isVerified,
  }) async {
    try {
      await dio.patch(
        '/api/admin/providers/$providerId/verification',
        data: {'is_verified': isVerified},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disableProvider(int providerId, {String? reason}) async {
    try {
      await dio.post(
        '/api/admin/providers/$providerId/disable',
        data: {'reason': reason},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> enableProvider(int providerId) async {
    try {
      await dio.post('/api/admin/providers/$providerId/enable');
    } catch (e) {
      rethrow;
    }
  }

  // Admin: Category CRUD
  Future<List<ServiceCategory>> getAdminCategories() async {
    try {
      final response = await dio.get('/api/admin/categories');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map(
              (item) =>
                  ServiceCategory.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceCategory> createCategory({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        '/api/admin/categories',
        data: {
          'name': name,
          'description': description ?? '',
          'is_active': isActive,
        },
      );
      return ServiceCategory.fromJson(
        Map<String, dynamic>.from(response.data['data']),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceCategory> updateCategory({
    required int categoryId,
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.put(
        '/api/admin/categories/$categoryId',
        data: {
          'name': name,
          'description': description ?? '',
          'is_active': isActive,
        },
      );
      return ServiceCategory.fromJson(
        Map<String, dynamic>.from(response.data['data'] ?? {}),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await dio.delete('/api/admin/categories/$categoryId');
    } catch (e) {
      rethrow;
    }
  }

  // Admin: User management
  Future<List<Map<String, dynamic>>> getAdminUsers({
    String? role,
    String? status,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (role != null) params['role'] = role;
      if (status != null) params['status'] = status;
      if (search != null) params['search'] = search;
      final response = await dio.get(
        '/api/admin/users',
        queryParameters: params,
      );
      final data = response.data['data'];
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserStatus({
    required int userId,
    required String status,
  }) async {
    try {
      await dio.patch(
        '/api/admin/users/$userId/status',
        data: {'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Admin: Order monitoring
  Future<List<Map<String, dynamic>>> getAdminOrders({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      final response = await dio.get(
        '/api/admin/orders',
        queryParameters: params,
      );
      final data = response.data['data'];
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Admin: Payment monitoring
  Future<Map<String, dynamic>> getAdminPayments({
    String? status,
    String? paymentType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (paymentType != null) params['payment_type'] = paymentType;
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      final response = await dio.get(
        '/api/admin/payments',
        queryParameters: params,
      );
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // Admin: Reports (treasurer summary merged)
  Future<Map<String, dynamic>> getAdminReportSummary({
    String? startDate,
    String? endDate,
    String groupBy = 'day',
  }) async {
    try {
      final params = <String, dynamic>{'group_by': groupBy};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      final response = await dio.get(
        '/api/admin/reports/summary',
        queryParameters: params,
      );
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminPaymentReport({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        '/api/admin/payments/report',
        queryParameters: queryParameters,
      );
      // Handle file response (CSV/Excel)
      if (response.data is String) {
        return {'success': true, 'message': 'File export berhasil'};
      }
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // Legacy treasurer endpoint (backward compat)
  Future<Map<String, dynamic>> getTreasurerReport({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        '/api/treasurer/payments/report',
        queryParameters: queryParameters,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getMetrics() async {
    try {
      final response = await dio.get('/api/metrics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

// Riverpod Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio: dio);
});
