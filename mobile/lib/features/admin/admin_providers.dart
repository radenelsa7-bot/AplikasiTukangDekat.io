import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/provider_model.dart';
import '../../core/services/api_service.dart';

final pendingProvidersProvider = FutureProvider<List<ProviderProfile>>((
  ref,
) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getPendingProviders();
  return response.data;
});

final adminVerificationControllerProvider =
    StateNotifierProvider<AdminVerificationController, AdminVerificationState>((
      ref,
    ) {
      return AdminVerificationController(ref);
    });

class AdminVerificationState {
  final bool isLoading;
  final int? processingProviderId;
  final String? errorMessage;

  const AdminVerificationState({
    this.isLoading = false,
    this.processingProviderId,
    this.errorMessage,
  });

  AdminVerificationState copyWith({
    bool? isLoading,
    int? processingProviderId,
    String? errorMessage,
  }) {
    return AdminVerificationState(
      isLoading: isLoading ?? this.isLoading,
      processingProviderId: processingProviderId,
      errorMessage: errorMessage,
    );
  }
}

class AdminVerificationController
    extends StateNotifier<AdminVerificationState> {
  AdminVerificationController(this._ref)
    : super(const AdminVerificationState());

  final Ref _ref;

  Future<bool> setVerification({
    required int providerId,
    required bool isVerified,
  }) async {
    state = state.copyWith(
      isLoading: true,
      processingProviderId: providerId,
      errorMessage: null,
    );

    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateProviderVerification(
        providerId: providerId,
        isVerified: isVerified,
      );
      // ignore: unused_result
      _ref.refresh(pendingProvidersProvider);
      state = state.copyWith(isLoading: false, processingProviderId: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        processingProviderId: null,
        errorMessage: 'Gagal update verifikasi: $e',
      );
      return false;
    }
  }
}
