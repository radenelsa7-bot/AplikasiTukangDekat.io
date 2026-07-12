import 'dart:typed_data';
import 'dart:convert';
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

  Future<List<Map<String, dynamic>>> getKota() async {
    try {
      final response = await dio.get('/api/catalog/wilayah/kota');
      final data = response.data['data'];
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getKecamatan(int kotaId) async {
    try {
      final response = await dio.get(
        '/api/catalog/wilayah/kota/$kotaId/kecamatan',
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

  Future<ProvidersResponse> getProvidersByCategory(
    int categoryId, {
    int? kotaId,
    int? kecamatanId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (kotaId != null) params['kota_id'] = kotaId;
      if (kecamatanId != null) params['kecamatan_id'] = kecamatanId;
      final response = await dio.get(
        '/api/catalog/categories/$categoryId/providers',
        queryParameters: params,
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

  Future<ProvidersResponse> searchProviders(
    String query, {
    int? kotaId,
    int? kecamatanId,
  }) async {
    try {
      final params = <String, dynamic>{'q': query};
      if (kotaId != null) params['kota_id'] = kotaId;
      if (kecamatanId != null) params['kecamatan_id'] = kecamatanId;
      final response = await dio.get(
        '/api/catalog/providers/search',
        queryParameters: params,
      );
      return ProvidersResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ===== ORDER ENDPOINTS =====

  Future<OrderData> createOrder(CreateOrderRequest request) async {
    try {
      final Object payload;
      if (request.attachmentPaths != null &&
          request.attachmentPaths!.isNotEmpty) {
        final form = FormData.fromMap(request.toJson());
        for (final path in request.attachmentPaths!) {
          form.files.add(
            MapEntry('damage_photos[]', await MultipartFile.fromFile(path)),
          );
        }
        payload = form;
      } else {
        payload = request.toJson();
      }

      final response = await dio.post('/api/orders', data: payload);
      return OrderData.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderData> createOrderWithFiles(
    Map<String, dynamic> fields,
    List<MultipartFile> files,
  ) async {
    try {
      final form = FormData();
      fields.forEach((k, v) {
        if (v != null) form.fields.add(MapEntry(k, v.toString()));
      });
      for (var f in files) {
        form.files.add(MapEntry('files[]', f));
      }
      final response = await dio.post('/api/orders', data: form);
      return OrderData.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProviderDashboard() async {
    try {
      final response = await dio.get('/api/provider/dashboard');
      return Map<String, dynamic>.from(response.data['data'] ?? {});
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

  Future<Map<String, dynamic>> getProviderProfile() async {
    try {
      final response = await dio.get('/api/provider/profile');
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProviderProfile({
    String? businessName,
    String? description,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (businessName != null) data['business_name'] = businessName;
      if (description != null) data['description'] = description;
      if (area != null) data['area'] = area;
      if (address != null) data['address'] = address;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;

      final response = await dio.put('/api/provider/profile', data: data);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProviderCoverage({
    required int kotaId,
    required List<int> kecamatanIds,
  }) async {
    try {
      final response = await dio.put(
        '/api/provider/coverage',
        data: {
          'kota_id': kotaId,
          'kecamatan_ids': kecamatanIds,
        },
      );
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<int> createProviderService({
    required int categoryId,
    required String name,
    String? description,
    required int basePrice,
    String? priceUnit,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        '/api/provider/services',
        data: {
          'category_id': categoryId,
          'name': name,
          'description': description,
          'base_price': basePrice,
          'price_unit': priceUnit,
          'is_active': isActive,
        },
      );
      return response.data['data']['service_id'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProviderService({
    required int serviceId,
    int? categoryId,
    String? name,
    String? description,
    int? basePrice,
    String? priceUnit,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (categoryId != null) data['category_id'] = categoryId;
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (basePrice != null) data['base_price'] = basePrice;
      if (priceUnit != null) data['price_unit'] = priceUnit;
      if (isActive != null) data['is_active'] = isActive;

      final response = await dio.patch(
        '/api/provider/services/$serviceId',
        data: data,
      );
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendChatbotMessage(String message) async {
    try {
      final response = await dio.post(
        '/api/chatbot/send',
        data: {'message': message},
      );
      final data = response.data;
      if (data is Map &&
          data['data'] != null &&
          data['data']['reply'] != null) {
        final replyRaw = data['data']['reply'].toString();
        try {
          if (replyRaw.startsWith('{') || replyRaw.startsWith('[')) {
            final decoded = jsonDecode(replyRaw);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
          }
        } catch (_) {
          // ignore JSON decode errors, fallbacks below
        }

        return {'reply': replyRaw, 'actions': []};
      }
      return {'reply': data.toString(), 'actions': []};
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
    List<MultipartFile> initialConditionPhotos = const [],
    List<MultipartFile> finalConditionPhotos = const [],
    List<MultipartFile> receiptPhotos = const [],
  }) async {
    try {
      final form = FormData();
      form.fields.add(MapEntry('final_price', finalPrice.toString()));
      for (final file in initialConditionPhotos) {
        form.files.add(MapEntry('initial_condition_photos[]', file));
      }
      for (final file in finalConditionPhotos) {
        form.files.add(MapEntry('final_condition_photos[]', file));
      }
      for (final file in receiptPhotos) {
        form.files.add(MapEntry('receipt_photos[]', file));
      }
      await dio.post(
        '/api/orders/$orderId/complete',
        data: form,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decideFinalPrice({
    required int orderId,
    required String action,
    String? reason,
  }) async {
    try {
      await dio.post(
        '/api/orders/$orderId/final-price/approve',
        data: {
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
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
    } on DioException catch (e) {
      // Better error messages for common review errors
      if (e.response?.statusCode == 409) {
        final errorMsg = e.response?.data?['message'] ?? '';
        if (errorMsg.contains('already been submitted')) {
          throw Exception('Anda sudah memberikan ulasan untuk order ini');
        } else if (errorMsg.contains('closed orders')) {
          throw Exception(
            'Ulasan hanya dapat diberikan untuk order yang sudah selesai',
          );
        }
      }
      rethrow;
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

  Future<Uint8List> getAdminPaymentReport({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        '/api/admin/payments/report',
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data is Uint8List) {
        return response.data as Uint8List;
      }
      return Uint8List.fromList(List<int>.from(response.data));
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
