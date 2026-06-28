import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthStorageService {
  final FlutterSecureStorage _storage;

  AuthStorageService({required FlutterSecureStorage storage})
    : _storage = storage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';
  static const String _userFullNameKey = 'user_full_name';
  static const String _userPhoneNumberKey = 'user_phone_number';
  static const String _userProfilePhotoPathKey = 'user_profile_photo_path';

  // Save token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save user data
  Future<void> saveUserData({
    required int userId,
    required String userRole,
    required String userEmail,
    String? fullName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userRoleKey, value: userRole);
    await _storage.write(key: _userEmailKey, value: userEmail);

    if (fullName != null) {
      await _storage.write(key: _userFullNameKey, value: fullName);
    } else {
      await _storage.delete(key: _userFullNameKey);
    }

    if (phoneNumber != null) {
      await _storage.write(key: _userPhoneNumberKey, value: phoneNumber);
    } else {
      await _storage.delete(key: _userPhoneNumberKey);
    }

    if (profilePhotoPath != null) {
      await _storage.write(
        key: _userProfilePhotoPathKey,
        value: profilePhotoPath,
      );
    } else {
      await _storage.delete(key: _userProfilePhotoPathKey);
    }
  }

  // Get user ID
  Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  // Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Get user full name
  Future<String?> getUserFullName() async {
    return await _storage.read(key: _userFullNameKey);
  }

  // Get user phone number
  Future<String?> getUserPhoneNumber() async {
    return await _storage.read(key: _userPhoneNumberKey);
  }

  // Get user profile photo path
  Future<String?> getUserProfilePhotoPath() async {
    return await _storage.read(key: _userProfilePhotoPathKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

// Riverpod Provider
final authStorageProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService(storage: const FlutterSecureStorage());
});
