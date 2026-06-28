class AuthResponse {
  final String message;
  final String? token;
  final UserData? user;

  AuthResponse({required this.message, this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final flattenedData = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{};

    return AuthResponse(
      message: json['message'] ?? flattenedData['message'] ?? '',
      token: json['token'] ?? flattenedData['token'],
      user: (json['user'] is Map<String, dynamic>)
          ? UserData.fromJson(json['user'] as Map<String, dynamic>)
          : (flattenedData['user'] is Map<String, dynamic>)
          ? UserData.fromJson(flattenedData['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? fullName;
  final String? phoneNumber;
  final String? profilePhotoPath;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.fullName,
    this.phoneNumber,
    this.profilePhotoPath,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }
}
