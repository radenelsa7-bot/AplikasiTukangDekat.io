import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/models/category_model.dart';
import '../../core/models/provider_model.dart';
import '../../core/services/api_service.dart';
import 'catalog_providers.dart';

final providerServicesControllerProvider = StateNotifierProvider<ProviderServicesController, ProviderServicesState>(
  (ref) => ProviderServicesController(ref),
);

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

  Future<bool> refreshProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final _ = await _ref.refresh(providerProfileProvider.future);
      state = state.copyWith(isLoading: false);
      return true;
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
}

class ProviderServicesPage extends ConsumerWidget {
  const ProviderServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(providerProfileProvider);
    final controllerState = ref.watch(providerServicesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Layanan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controllerState.isLoading
                ? null
                : () => ref.read(providerServicesControllerProvider.notifier).refreshProfile(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Gagal memuat profil provider: $err')),
        data: (profile) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Provider',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                profile.businessName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit Profil',
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => ProviderProfileDialog(profile: profile),
                                );
                                if (result == true) {
                                  // refresh profile
                                  await ref.read(providerServicesControllerProvider.notifier).refreshProfile();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profil provider berhasil diperbarui')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (profile.description != null && profile.description!.isNotEmpty)
                          _buildInfoRow('Deskripsi', profile.description!),
                        _buildInfoRow('Area', profile.area ?? '-'),
                        _buildInfoRow('Alamat', profile.address ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (controllerState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controllerState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: profile.services.length,
                    itemBuilder: (context, index) {
                      final service = profile.services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            '${service.categoryName ?? 'Layanan'} · Rp${service.basePrice} / ${service.priceUnit}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (_) => ProviderServiceDialog(service: service),
                              );
                              if (result == true) {
                                ref.read(providerServicesControllerProvider.notifier).refreshProfile();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Layanan berhasil diperbarui')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const ProviderServiceDialog(),
          );
          if (result == true) {
            if (!context.mounted) return;
            ref.read(providerServicesControllerProvider.notifier).refreshProfile();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layanan baru berhasil ditambahkan')),
            );
          }
        },
        tooltip: 'Tambah Layanan',
        child: const Icon(Icons.add),
      ),
      
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class ProviderProfileDialog extends ConsumerStatefulWidget {
  final ProviderProfile profile;

  const ProviderProfileDialog({super.key, required this.profile});

  @override
  ConsumerState<ProviderProfileDialog> createState() => _ProviderProfileDialogState();
}

class _ProviderProfileDialogState extends ConsumerState<ProviderProfileDialog> {
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _businessNameCtrl = TextEditingController(text: widget.profile.businessName);
    _descriptionCtrl = TextEditingController(text: widget.profile.description ?? '');
    _areaCtrl = TextEditingController(text: widget.profile.area ?? '');
    _addressCtrl = TextEditingController(text: widget.profile.address ?? '');
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final controller = ref.read(providerServicesControllerProvider.notifier);
    final success = await controller.updateProfile(
      businessName: _businessNameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      area: _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );
    setState(() => _isSaving = false);
    if (success && mounted) {
      // Invalidate provider detail cache so other pages reflect the update
      try {
        ref.invalidate(providerDetailProvider(widget.profile.id));
      } catch (_) {}
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil Provider'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _businessNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nama Usaha',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areaCtrl,
            decoration: InputDecoration(
              labelText: 'Area',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'Alamat',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }
}

class ProviderServiceDialog extends ConsumerStatefulWidget {
  final ProviderService? service;

  const ProviderServiceDialog({super.key, this.service});

  @override
  ConsumerState<ProviderServiceDialog> createState() => _ProviderServiceDialogState();
}

class _ProviderServiceDialogState extends ConsumerState<ProviderServiceDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  bool _isSaving = false;

  late Future<List<ServiceCategory>> _categoriesFuture;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.service?.basePrice.toString() ?? '');
    _unitCtrl = TextEditingController(text: widget.service?.priceUnit ?? '');
    if (widget.service == null) {
      _categoriesFuture = _loadCategories();
    } else {
      _selectedCategoryId = widget.service?.categoryId;
      _categoriesFuture = Future.value([]);
    }
  }

  Future<List<ServiceCategory>> _loadCategories() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.getCategories();
    final categories = response.data;
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
    return categories;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final controller = ref.read(providerServicesControllerProvider.notifier);
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final unit = _unitCtrl.text.trim();

    if (name.isEmpty || price <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama layanan dan harga harus diisi dengan benar')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final selectedCategoryId = widget.service?.categoryId ?? _selectedCategoryId;
    if (selectedCategoryId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori layanan harus dipilih')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final success = widget.service == null
        ? await controller.createService(
            categoryId: selectedCategoryId,
            name: name,
            basePrice: price,
            priceUnit: unit.isEmpty ? 'per_job' : unit,
          )
        : await controller.updateService(
            serviceId: widget.service!.id,
            name: name,
            basePrice: price,
            priceUnit: unit.isEmpty ? 'per_job' : unit,
          );

    setState(() => _isSaving = false);
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Tambah Layanan' : 'Edit Layanan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.service == null)
            FutureBuilder<List<ServiceCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Gagal memuat kategori: ${snapshot.error}'),
                  );
                }

                final categories = snapshot.data ?? [];
                return DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                );
              },
            ),
          if (widget.service != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(
                    'Kategori: ${widget.service?.categoryName ?? 'Tidak tersedia'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nama Layanan',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            decoration: InputDecoration(
              labelText: 'Harga Dasar',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitCtrl,
            decoration: InputDecoration(
              labelText: 'Satuan Harga (contoh: per kunjungan)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }
}
