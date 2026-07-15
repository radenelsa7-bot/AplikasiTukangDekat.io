import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/provider_model.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/app_text_field.dart';
import 'catalog_providers.dart';
import '../maps/location_picker_screen.dart'
    show LocationPickerScreen, LocationResult;

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
  Future<bool> refreshProfile({bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastRefreshTime) < _minRefreshInterval) {
      // Rate limited - skip this refresh call
      state = state.copyWith(isLoading: false);
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
      await refreshProfile(force: true);
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
      await refreshProfile(force: true);
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
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateProviderProfile(
        businessName: businessName,
        description: description,
        area: area,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      await refreshProfile(force: true);
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
      await refreshProfile(force: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteService(int serviceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _ref.read(apiServiceProvider).deleteProviderService(serviceId);
      await refreshProfile(force: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data is Map
            ? e.response?.data['message']?.toString()
            : e.message,
      );
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
  final _businessNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  int? _loadedProfileId;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _populateProfileFields(ProviderProfile profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _businessNameCtrl.text = profile.businessName;
    _descriptionCtrl.text = profile.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(providerServicesControllerProvider.notifier);
    final state = ref.watch(providerServicesControllerProvider);
    final profileAsync = ref.watch(providerProfileProvider);
    // Preload categories so the add-service form can always offer a category.
    ref.watch(categoriesProvider);

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
          _populateProfileFields(profile);
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
                          controller: _businessNameCtrl,
                          label: 'Nama Usaha',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _descriptionCtrl,
                          label: 'Deskripsi',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  final name = _businessNameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Nama usaha wajib diisi')),
                                    );
                                    return;
                                  }
                                  final ok = await controller.updateProfile(
                                    businessName: name,
                                    description: _descriptionCtrl.text.trim(),
                                    area: profile.area,
                                    address: profile.address,
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Profil berhasil disimpan' : 'Gagal menyimpan profil'),
                                      backgroundColor: ok ? Colors.green : AppTheme.danger,
                                    ),
                                  );
                                },
                          child: const Text('Simpan Profil'),
                        ),
                                                const Divider(height: 24),
                        Text(
                          'Lokasi Provider',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lokasi ini dipakai untuk menampilkan posisi Anda ke '
                          'customer pada peta pelacakan pesanan.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              (profile.latitude != null &&
                                      profile.longitude != null)
                                  ? Icons.my_location
                                  : Icons.location_off,
                              size: 18,
                              color: (profile.latitude != null &&
                                      profile.longitude != null)
                                  ? AppTheme.orange
                                  : AppTheme.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (profile.latitude != null &&
                                        profile.longitude != null)
                                    ? (profile.address?.isNotEmpty == true
                                          ? profile.address!
                                          : '${profile.latitude}, ${profile.longitude}')
                                    : 'Lokasi belum diatur',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _setProviderLocation(profile),
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: Text(
                            (profile.latitude != null &&
                                    profile.longitude != null)
                                ? 'Perbarui Lokasi (GPS/Peta)'
                                : 'Atur Lokasi (GPS/Peta)',
                          ),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit layanan',
                              onPressed: () => _showEditServiceDialog(context, service),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.danger,
                              ),
                              tooltip: 'Hapus layanan',
                              onPressed: state.isLoading
                                  ? null
                                  : () => _confirmDeleteService(service),
                            ),
                            Switch(
                              value: service.isActive,
                              onChanged: state.isLoading ? null : (val) => controller.updateService(
                                serviceId: service.id,
                                isActive: val,
                              ),
                            ),
                          ],
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

  Future<void> _setProviderLocation(ProviderProfile profile) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS tidak aktif. Silakan aktifkan GPS.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
 
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi belum diberikan.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
 
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: profile.latitude,
          initialLng: profile.longitude,
          initialAddress: profile.address,
        ),
      ),
    );
    if (result == null || !mounted) return;
 
    final ok = await ref
        .read(providerServicesControllerProvider.notifier)
        .updateProfile(
          businessName: profile.businessName,
          description: profile.description,
          area: profile.area,
          address: result.address,
          latitude: result.latitude,
          longitude: result.longitude,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Lokasi provider diperbarui' : 'Gagal memperbarui lokasi',
        ),
        backgroundColor: ok ? Colors.green : AppTheme.danger,
      ),
    );
  }
 
  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final descriptionCtrl = TextEditingController();
        final priceCtrl = TextEditingController();
        final unitCtrl = TextEditingController(text: 'per kunjungan');
        final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
        int? categoryId = categories.isNotEmpty ? categories.first.id : null;

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
              DropdownButtonFormField<int>(
                value: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                )).toList(),
                onChanged: (value) => categoryId = value,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: descriptionCtrl,
                label: 'Deskripsi (opsional)',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: priceCtrl,
                label: 'Harga Dasar',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: unitCtrl, label: 'Satuan harga'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = int.tryParse(priceCtrl.text) ?? 0;
                if (name.isNotEmpty && price > 0 && categoryId != null) {
                  final ok = await ref.read(providerServicesControllerProvider.notifier).createService(
                    categoryId: categoryId!,
                    name: name,
                    description: descriptionCtrl.text.trim(),
                    basePrice: price,
                    priceUnit: unitCtrl.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Layanan ditambahkan' : 'Gagal menambahkan layanan')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditServiceDialog(BuildContext context, ProviderService service) {
    final nameCtrl = TextEditingController(text: service.name);
    final descriptionCtrl = TextEditingController(text: service.description ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Layanan'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(controller: nameCtrl, label: 'Nama Layanan'),
            const SizedBox(height: 12),
            AppTextField(controller: descriptionCtrl, label: 'Deskripsi', maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final ok = await ref.read(providerServicesControllerProvider.notifier).updateService(
                serviceId: service.id,
                name: name,
                description: descriptionCtrl.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Layanan berhasil diperbarui' : 'Gagal memperbarui layanan')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteService(ProviderService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Layanan?'),
        content: Text('Hapus layanan "${service.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = ref.read(providerServicesControllerProvider.notifier);
    final ok = await controller.deleteService(service.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Layanan berhasil dihapus'
              : controller.state.errorMessage ?? 'Gagal menghapus layanan',
        ),
        backgroundColor: ok ? Colors.green : AppTheme.danger,
      ),
    );
  }
}
