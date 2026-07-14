import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/services/api_service.dart';
import 'package:image/image.dart' as img_pkg;
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../core/models/order_model.dart';
import '../../core/models/provider_model.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../maps/location_picker_screen.dart' show LocationPickerScreen, LocationResult;



import 'my_orders_page.dart';
import 'order_providers.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  final int providerId;
  final int categoryId;
  final List<ProviderService> services;
  final List<ProviderCoverage> coverages;

  const CreateOrderPage({
    super.key,
    required this.providerId,
    required this.categoryId,
    required this.services,
    this.coverages = const [],
  });

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _attachmentUrlsCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  ProviderService? _selectedService;
  List<Map<String, dynamic>> _kotaList = [];
  List<Map<String, dynamic>> _kecamatanList = [];
  int? _selectedKotaId;
  int? _selectedKecamatanId;
  bool _isLoadingWilayah = false;
  bool _isLoadingKecamatan = false;
  List<XFile> _damagePhotos = [];
  String _damageLevel = 'LIGHT';

  bool get _hasCoverageFilter => widget.coverages.isNotEmpty;

  List<int> get _coverageKotaIds {
    return widget.coverages
        .where((coverage) => coverage.isActive && coverage.kotaId != null)
        .map((coverage) => coverage.kotaId!)
        .toSet()
        .toList();
  }

  List<int> _coverageKecamatanIdsForKota(int kotaId) {
    return widget.coverages
        .where(
          (coverage) =>
              coverage.isActive &&
              coverage.kotaId == kotaId &&
              coverage.kecamatanId > 0,
        )
        .map((coverage) => coverage.kecamatanId)
        .toSet()
        .toList();
  }

  Map<String, dynamic> get _damageInfo {
    final basePrice = _selectedService?.basePrice ?? 0;
    final minMultiplier = _damageLevel == 'HEAVY'
        ? 1.5
        : (_damageLevel == 'MEDIUM' ? 1.0 : 0.8);
    final maxMultiplier = _damageLevel == 'HEAVY'
        ? 2.5
        : (_damageLevel == 'MEDIUM' ? 1.5 : 1.0);
    final description = _damageLevel == 'HEAVY'
        ? 'Kerusakan berat: membutuhkan pembongkaran besar, komponen utama, risiko tambahan, atau kunjungan lanjutan.'
        : (_damageLevel == 'MEDIUM'
              ? 'Kerusakan sedang: perlu pembongkaran ringan, penggantian komponen kecil, atau durasi pengerjaan lebih lama.'
              : 'Kerusakan ringan: kendala kecil, pengecekan cepat, penyetelan, atau perbaikan tanpa penggantian komponen besar.');
    return {
      'min': (basePrice * minMultiplier).round(),
      'max': (basePrice * maxMultiplier).round(),
      'description': description,
    };
  }

  @override
  void initState() {
    super.initState();
    // Set default ke service pertama jika ada
    if (widget.services.isNotEmpty) {
      _selectedService = widget.services.first;
    }
    Future.microtask(_loadKota);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _attachmentUrlsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDamagePhotos() async {
    final photos = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (photos.isEmpty || !mounted) return;
    setState(() {
      _damagePhotos = photos.take(5).toList();
    });
  }

  Future<void> _loadKota() async {
    setState(() => _isLoadingWilayah = true);
    try {
      final api = ref.read(apiServiceProvider);
      final kota = await api.getKota();
      if (!mounted) return;
      final filteredKota = _hasCoverageFilter
          ? kota.where((item) {
              final id = (item['id'] as num).toInt();
              return _coverageKotaIds.contains(id);
            }).toList()
          : kota;
      setState(() {
        _kotaList = filteredKota;
        _selectedKotaId = filteredKota.isNotEmpty
            ? (filteredKota.first['id'] as num).toInt()
            : null;
      });
      if (_selectedKotaId != null) {
        await _loadKecamatan(_selectedKotaId!);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat daftar wilayah'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingWilayah = false);
    }
  }

  Future<void> _loadKecamatan(int kotaId) async {
    setState(() => _isLoadingKecamatan = true);
    try {
      final api = ref.read(apiServiceProvider);
      final kecamatan = await api.getKecamatan(kotaId);
      if (!mounted) return;
      final filteredKecamatan = _hasCoverageFilter
          ? kecamatan.where((item) {
              final id = (item['id'] as num).toInt();
              return _coverageKecamatanIdsForKota(kotaId).contains(id);
            }).toList()
          : kecamatan;
      setState(() {
        _kecamatanList = filteredKecamatan;
        _selectedKecamatanId = filteredKecamatan.isNotEmpty
            ? (filteredKecamatan.first['id'] as num).toInt()
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kecamatanList = [];
        _selectedKecamatanId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat daftar kecamatan')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingKecamatan = false);
    }
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih layanan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedKotaId == null || _selectedKecamatanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kota dan kecamatan layanan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasCoverageFilter) {
      final kotaCovered = _coverageKotaIds.contains(_selectedKotaId);
      final kecamatanCovered = _coverageKecamatanIdsForKota(
        _selectedKotaId!,
      ).contains(_selectedKecamatanId);
      if (!kotaCovered || !kecamatanCovered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Provider ini tidak melayani kota/kecamatan yang dipilih',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // If user selected images, compress them client-side and send in single multipart request
    final api = ref.read(apiServiceProvider);
    if (_selectedImages.isNotEmpty) {
      final parts = <MultipartFile>[];
      for (final xfile in _selectedImages) {
        try {
          final originalBytes = await xfile.readAsBytes();
          final decoded = img_pkg.decodeImage(originalBytes);
          final pathLower = xfile.path.toLowerCase();
          late List<int> encoded;
          String mime;
          String filename = xfile.name;

          if (decoded != null) {
            var resized = decoded;
            if (resized.width > 1280) {
              resized = img_pkg.copyResize(resized, width: 1280);
            }

            if (pathLower.endsWith('.png')) {
              encoded = img_pkg.encodePng(resized);
              mime = 'image/png';
              if (encoded.length > 5 * 1024 * 1024) {
                encoded = img_pkg.encodeJpg(resized, quality: 80);
                mime = 'image/jpeg';
                filename = filename.replaceAll(
                  RegExp(r'\.png$', caseSensitive: false),
                  '.jpg',
                );
              }
            } else {
              int quality = 80;
              encoded = img_pkg.encodeJpg(resized, quality: quality);
              mime = 'image/jpeg';
              while (encoded.length > 5 * 1024 * 1024 && quality > 30) {
                quality -= 10;
                encoded = img_pkg.encodeJpg(resized, quality: quality);
              }
              if (encoded.length > 5 * 1024 * 1024) {
                resized = img_pkg.copyResize(resized, width: 960);
                quality = 70;
                encoded = img_pkg.encodeJpg(resized, quality: quality);
              }
            }
          } else {
            encoded = originalBytes;
            mime = pathLower.endsWith('.png') ? 'image/png' : 'image/jpeg';
          }

          if (encoded.length > 5 * 1024 * 1024) {
            final decodedAgain =
                img_pkg.decodeImage(Uint8List.fromList(encoded)) ??
                img_pkg.Image(width: 800, height: 600);
            final scaled = img_pkg.copyResize(decodedAgain, width: 800);
            encoded = img_pkg.encodeJpg(scaled, quality: 70);
            mime = 'image/jpeg';
            filename = filename.replaceAll(
              RegExp(r'\.png$', caseSensitive: false),
              '.jpg',
            );
          }

          parts.add(
            MultipartFile.fromBytes(
              encoded,
              filename: filename,
              contentType: MediaType.parse(mime),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memproses gambar')),
          );
          return;
        }
      }

      // Prepare fields for order
      final fields = <String, dynamic>{
        'provider_id': widget.providerId,
        'category_id': widget.categoryId,
        'provider_service_id': _selectedService?.id,
        'kota_id': _selectedKotaId,
        'kecamatan_id': _selectedKecamatanId,
        'schedule_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(
          DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ),
        ),
        'address': _addressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'damage_level': _damageLevel,
        'damage_description': _damageInfo['description'],
        'estimated_price_min': _damageInfo['min'],
        'estimated_price_max': _damageInfo['max'],
        'estimated_price': _selectedService?.basePrice,
      };

      try {
        await api.createOrderWithFiles(fields, parts);
        // navigate back with success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        return;
      } catch (e) {
        final errorMessage = e is DioException && e.response != null
            ? (e.response?.data['message']?.toString() ?? 'Gagal membuat order')
            : 'Gagal membuat order';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        return;
      }
    }

    final request = CreateOrderRequest(
      providerId: widget.providerId,
      categoryId: widget.categoryId,
      providerServiceId: _selectedService?.id,
      kotaId: _selectedKotaId!,
      kecamatanId: _selectedKecamatanId!,
      scheduleAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ),
      ),
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      damageLevel: _damageLevel,
      damageDescription: _damageInfo['description'],
      estimatedPriceMin: _damageInfo['min'],
      estimatedPriceMax: _damageInfo['max'],
      estimatedPrice: _selectedService?.basePrice,
      attachmentUrls: _attachmentUrlsCtrl.text.trim().isEmpty
          ? null
          : _attachmentUrlsCtrl.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
      attachmentPaths: _damagePhotos.map((photo) => photo.path).toList(),
    );

    final success = await ref
        .read(createOrderControllerProvider.notifier)
        .createOrder(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyOrdersPage()),
      );
    } else {
      final errorMsg =
          ref.read(createOrderControllerProvider).errorMessage ?? 'Order gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOrderControllerProvider);
    final authState = ref.watch(authControllerProvider);

    if (authState.userRole != 'CUSTOMER') {
      return Scaffold(
        appBar: AppBar(title: const Text('Buat Order')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.block, size: 72, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Hanya pelanggan (CUSTOMER) dapat membuat order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Order')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Order',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),

                    // Pilih Layanan
                    Text(
                      'Pilih Layanan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (widget.services.isNotEmpty)
                      DropdownButton<ProviderService>(
                        isExpanded: true,
                        value: _selectedService,
                        items: widget.services.map((service) {
                          return DropdownMenuItem(
                            value: service,
                            child: Text(
                              '${service.name} - Rp${service.basePrice}/${service.priceUnit}',
                            ),
                          );
                        }).toList(),
                        onChanged: (ProviderService? newService) {
                          setState(() => _selectedService = newService);
                        },
                      )
                    else
                      const Text('Tidak ada layanan tersedia'),
                    const SizedBox(height: 24),

                    Text(
                      'Wilayah Layanan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_hasCoverageFilter) ...[
                      Text(
                        'Provider ini melayani ${widget.coverages.where((c) => c.isActive).length} kecamatan.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_isLoadingWilayah)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      )
                    else ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedKotaId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Kota',
                          prefixIcon: const Icon(Icons.location_city),
                          errorText: state.fieldErrors['kota_id'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _kotaList.map((item) {
                          final id = (item['id'] as num).toInt();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(item['name']?.toString() ?? '-'),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() {
                            _selectedKotaId = value;
                            _selectedKecamatanId = null;
                            _kecamatanList = [];
                          });
                          await _loadKecamatan(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingKecamatan)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<int>(
                          initialValue: _selectedKecamatanId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kecamatan',
                            prefixIcon: const Icon(Icons.map_outlined),
                            errorText: state.fieldErrors['kecamatan_id'],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _kecamatanList.map((item) {
                            final id = (item['id'] as num).toInt();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(item['name']?.toString() ?? '-'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedKecamatanId = value);
                          },
                        ),
                    ],
                    const SizedBox(height: 16),
                    // Pilih Layanan
                    Text(
                      'Pilih Layanan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (widget.services.isNotEmpty)
                      DropdownButton<ProviderService>(
                        isExpanded: true,
                        value: _selectedService,
                        items: widget.services.map((service) {
                          return DropdownMenuItem(
                            value: service,
                            child: Text(
                              '${service.name} - Rp${service.basePrice}/${service.priceUnit}',
                            ),
                          );
                        }).toList(),
                        onChanged: (ProviderService? newService) {
                          setState(() => _selectedService = newService);
                        },
                      )
                    else
                      const Text('Tidak ada layanan tersedia'),
                    const SizedBox(height: 24),

                    Text(
                      'Kondisi Kerusakan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDamageChoice('LIGHT', 'Ringan'),
                        _buildDamageChoice('MEDIUM', 'Sedang'),
                        _buildDamageChoice('HEAVY', 'Berat'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_damageInfo['description']}\nEstimasi range: Rp${_damageInfo['min']} - Rp${_damageInfo['max']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alamat
                    const Text(
                      'Alamat Lokasi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
        OutlinedButton.icon(
                      onPressed: () async {
                        // CUSTOMER wajib aktifkan lokasi sebelum memilih titik pemesanan
                        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lokasi GPS tidak aktif. Silakan aktifkan GPS untuk melanjutkan.'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        var permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }

                        if (!context.mounted) return;
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Izin lokasi belum diberikan. Silakan aktifkan untuk melanjutkan.'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }

                        final result = await Navigator.of(context).push<LocationResult>(
                          MaterialPageRoute(
                            builder: (_) => const LocationPickerScreen(),
                          ),
                        );
                        if (result != null && mounted) {
                          _addressCtrl.text = result.address;
                        }
                      },

                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Pilih Lewat Google Maps'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: AppTheme.orange.withValues(alpha: 0.5),
                        ),
                        foregroundColor: AppTheme.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _addressCtrl,
                      label: 'Atau tulis alamat lengkap',
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.location_on),
                      errorText: state.fieldErrors['address'],
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) {
                          return 'Alamat wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Catatan
                    AppTextField(
                      controller: _notesCtrl,
                      label: 'Catatan Tambahan (opsional)',
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.note),
                      errorText: state.fieldErrors['notes'],
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _pickDamagePhotos,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _damagePhotos.isEmpty
                            ? 'Upload Foto Kerusakan'
                            : '${_damagePhotos.length} foto dipilih',
                      ),
                    ),
                    if (state.fieldErrors['damage_photos.0'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        state.fieldErrors['damage_photos.0']!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _attachmentUrlsCtrl,
                      label: 'URL Foto Tambahan (opsional, 1 URL per baris)',
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.link),
                      errorText: state.fieldErrors['attachment_urls.0'],
                    ),
                    const SizedBox(height: 16),

                    // Tanggal
                    Text('Tanggal Pekerjaan'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_selectedDate!)
                                  : 'Pilih tanggal',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Jam
                    Text('Jam Pekerjaan'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 12),
                            Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : 'Pilih jam',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Pembayaran',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Akan ada 2 tahap pembayaran'),
                          const Text('• DP 50% saat order diterima'),
                          const Text('• Sisa 50% saat pekerjaan selesai'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Buat Order',
                        isLoading: state.isLoading,
                        onPressed: _createOrder,
                      ),
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageChoice(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _damageLevel == value,
      onSelected: (_) => setState(() => _damageLevel = value),
    );
  }
}
