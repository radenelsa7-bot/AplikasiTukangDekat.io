import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage_service.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  void updateState(AuthState Function(AuthState) update) {
    state = update(state);
  }

  Future<void> loadToken() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _ref.read(authStorageProvider).getToken();
      final userId = await _ref.read(authStorageProvider).getUserId();
      final userRole = await _ref.read(authStorageProvider).getUserRole();
      final userEmail = await _ref.read(authStorageProvider).getUserEmail();
      final fullName = await _ref.read(authStorageProvider).getUserFullName();
      final phoneNumber = await _ref
          .read(authStorageProvider)
          .getUserPhoneNumber();
      final profilePhotoPath = await _ref
          .read(authStorageProvider)
          .getUserProfilePhotoPath();

      if (token != null) {
        _ref.read(apiServiceProvider).setToken(token);
        state = AuthState(
          isLoading: false,
          token: token,
          userId: userId,
          userRole: userRole,
          userEmail: userEmail,
          userFullName: fullName,
          userPhoneNumber: phoneNumber,
          userProfilePhotoPath: profilePhotoPath,
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load token: $e',
      );
    }
  }

  Future<bool> register({
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
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      fieldErrors: {},
    );
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        categoryId: categoryId,
        businessName: businessName,
        serviceName: serviceName,
        basePrice: basePrice,
      );

      state = state.copyWith(isLoading: false, fieldErrors: {});
      return true;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (e.response?.statusCode == 422 &&
          responseData is Map<String, dynamic>) {
        final fieldErrors = <String, String?>{};
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              fieldErrors[key] = value.first?.toString();
            } else if (value != null) {
              fieldErrors[key] = value.toString();
            }
          });
        }

        state = state.copyWith(
          isLoading: false,
          errorMessage: responseData['message'] ?? 'Registration failed',
          fieldErrors: fieldErrors,
        );
        return false;
      }

      final errorMsg = responseData is Map<String, dynamic>
          ? responseData['message'] ?? 'Registration failed'
          : 'Registration failed';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.login(email: email, password: password);

      if (response.token != null && response.user != null) {
        // Save token dan user data
        await _ref.read(authStorageProvider).saveToken(response.token!);
        await _ref
            .read(authStorageProvider)
            .saveUserData(
              userId: response.user!.id,
              userRole: response.user!.role,
              userEmail: response.user!.email,
              fullName: response.user!.fullName,
              phoneNumber: response.user!.phoneNumber,
              profilePhotoPath: response.user!.profilePhotoPath,
            );

        // Set token di Dio
        apiService.setToken(response.token!);

        state = AuthState(
          isLoading: false,
          token: response.token,
          userId: response.user!.id,
          userRole: response.user!.role,
          userEmail: response.user!.email,
          userFullName: response.user!.fullName,
          userPhoneNumber: response.user!.phoneNumber,
          userProfilePhotoPath: response.user!.profilePhotoPath,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid response',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMsg;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final url = ApiConfig.baseUrl;
        errorMsg =
            'Tidak bisa terhubung ke server ($url). Pastikan:\n'
            '1. Backend jalan: php artisan serve --host=0.0.0.0\n'
            '2. HP & komputer di WiFi yang sama\n'
            '3. IP address benar di .env atau --dart-define';
        debugPrint('[Login] Connection failed to: $url');
        debugPrint('[Login] Error: ${e.message}');
      } else {
        errorMsg =
            e.response?.data['email']?[0] ??
            e.response?.data['message'] ??
            'Login gagal';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.logout();
      apiService.clearToken();
      await _ref.read(authStorageProvider).clearAll();
      state = const AuthState(isLoading: false);
    } catch (e) {
      // Even if logout fails on server, clear local data
      final apiService = _ref.read(apiServiceProvider);
      apiService.clearToken();
      await _ref.read(authStorageProvider).clearAll();
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> deleteProfilePhoto() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final result = await apiService.deleteProfilePhoto();

      if (result['user'] is Map<String, dynamic>) {
        final user = result['user'] as Map<String, dynamic>;
        final fullName = user['full_name'] as String?;
        final phoneNumber = user['phone_number'] as String?;
        final profilePhotoPath = user['profile_photo_path'] as String?;

        await _ref
            .read(authStorageProvider)
            .saveUserData(
              userId: user['id'] ?? state.userId ?? 0,
              userRole: user['role'] ?? state.userRole ?? 'CUSTOMER',
              userEmail: user['email'] ?? state.userEmail ?? '',
              fullName: fullName,
              phoneNumber: phoneNumber,
              profilePhotoPath: profilePhotoPath,
            );

        state = state.copyWith(
          isLoading: false,
          userFullName: fullName,
          userPhoneNumber: phoneNumber,
          userProfilePhotoPath: profilePhotoPath,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete profile photo: $e',
      );
      return false;
    }
  }
}
