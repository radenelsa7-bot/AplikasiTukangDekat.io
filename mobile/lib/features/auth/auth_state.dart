class AuthState {
  final bool isLoading;
  final String? token;
  final int? userId;
  final String? userRole;
  final String? userEmail;
  final String? errorMessage;
  final Map<String, String?> fieldErrors;

  const AuthState({
    this.isLoading = false,
    this.token,
    this.userId,
    this.userRole,
    this.userEmail,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({
    bool? isLoading,
    String? token,
    int? userId,
    String? userRole,
    String? userEmail,
    String? errorMessage,
    Map<String, String?>? fieldErrors,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}