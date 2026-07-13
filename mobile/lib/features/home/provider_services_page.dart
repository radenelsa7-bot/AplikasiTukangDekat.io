import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/provider_model.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/app_text_field.dart';

final providerServicesControllerProvider =
    StateNotifierProvider<ProviderServicesController, ProviderServicesState>((ref) {
  return ProviderServicesController(ref);
});

final providerProfileProvider = FutureProvider<ProviderProfile>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getProviderProfile();
  if (data['profile'] is Map<String, dynamic>) {
    return ProviderProfile.fromJson(Map<String, dynamic>.from(data['profile']));
  }
  throw Exception('Failed to load provider profile');
});

class ProviderServicesState {
  final bool isLoading;
  final String? errorMessage;

  ProviderServicesState({this.isLoading = false, this.errorMessage});

  ProviderServicesState copyWith({bool? isLoading, String? errorMessage}) {
    return ProviderServicesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ProviderServicesController extends StateNotifier<ProviderServicesState> {
  ProviderServicesController(this._ref) : super(ProviderServicesState());

  final Ref _ref;
  DateTime _lastRefreshTime = DateTime(0);
  static const _minRefreshInterval = Duration(seconds: 2);

  /// Refresh profile with debouncing to prevent API spam (429 error)
  Future<bool> refreshProfile() async {
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime) < _minRefreshInterval) {
      // Rate limited - skip this refresh call
      return false;
    }
    _lastRefreshTime = now;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final _ = await _ref.refresh(providerProfileProvider.future);
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      // Handle 429 Too Many Requests specifically
      if (e.response?.statusCode == 429) {
        _lastRefreshTime = DateTime.now().add(const Duration(seconds: 5)); // Back off longer
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Terlalu banyak request. Silakan tunggu sebentar dan coba lagi.',
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> createService({
    required int categoryId,
    required String name,
    String? description,
    required int basePrice,
    String? priceUnit,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.createProviderService(
        categoryId: categoryId,
        name: name,
        description: description,
        basePrice: basePrice,
        priceUnit: priceUnit,
      );
      await refreshProfile();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateService({
    required int serviceId,
    String? description,
    int? categoryId,
    String? name,
    int? basePrice,
    String? priceUnit,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateProviderService(
        serviceId: serviceId,
        categoryId: categoryId,
        name: name,
        description: description,
        basePrice: basePrice,
        priceUnit: priceUnit,
        isActive: isActive,
      );
      await refreshProfile();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({
    String? businessName,
    String? description,
    String? area,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateProviderProfile(
        businessName: businessName,
        description: description,
        area: area,
        address: address,
      );
      await refreshProfile();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateCoverage({
    required int kotaId,
    required List<int> kecamatanIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateProviderCoverage(
        kotaId: kotaId,
        kecamatanIds: kecamatanIds,
      );
      await refreshProfile();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = ProviderServicesState();
  }
}

class ProviderServicesPage extends ConsumerStatefulWidget {
  const ProviderServicesPage({super.key});

  @override
  ConsumerState<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends ConsumerState<ProviderServicesPage> {
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(providerServicesControllerProvider.notifier);
    final state = ref.watch(providerServicesControllerProvider);
    final profileAsync = ref.watch(providerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Saya'),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.orange),
        ),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat layanan: $err',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(providerProfileProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          // Handle error notification
          if (state.errorMessage != null && state.errorMessage!.contains('429')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppTheme.warning,
                  ),
                );
                controller.clearError();
              }
            });
          }

          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 50 && !_showFooter) {
                setState(() => _showFooter = true);
              } else if (notification.metrics.extentAfter > 100 && _showFooter) {
                setState(() => _showFooter = false);
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil Provider',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          initialValue: profile.businessName,
                          label: 'Nama Usaha',
                          onChanged: (v) {},
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          initialValue: profile.description ?? '',
                          label: 'Deskripsi',
                          maxLines: 2,
                          onChanged: (v) {},
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => controller.updateProfile(
                            businessName: profile.businessName,
                            description: profile.description,
                            area: profile.area,
                            address: profile.address,
                          ),
                          child: const Text('Simpan Profil'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Services Section
                const Text(
                  'Layanan Tersedia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (profile.services.isEmpty)
                  const Text('Belum ada layanan. Tambahkan layanan di bawah.')
                else
                  ...profile.services.map((service) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(service.name),
                        subtitle: Text('Rp${service.basePrice} / ${service.priceUnit}'),
                        trailing: Switch(
                          value: service.isActive,
                          onChanged: (val) => controller.updateService(
                            serviceId: service.id,
                            isActive: val,
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                // Add Service Button
                ElevatedButton.icon(
                  onPressed: () => _showAddServiceDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Layanan'),
                ),
                if (_showFooter) const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController();

        return AlertDialog(
          title: const Text('Tambah Layanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Nama Layanan',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: priceCtrl,
                label: 'Harga Dasar',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = int.tryParse(priceCtrl.text) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  ref.read(providerServicesControllerProvider.notifier).createService(
                    categoryId: 1,
                    name: name,
                    basePrice: price,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}