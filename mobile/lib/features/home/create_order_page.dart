import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../core/models/order_model.dart';
import '../../core/models/provider_model.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  final int providerId;
  final int categoryId;
  final List<ProviderService> services;

  const CreateOrderPage({
    super.key,
    required this.providerId,
    required this.categoryId,
    required this.services,
  });

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  ProviderService? _selectedService;

  @override
  void initState() {
    super.initState();
    // Set default ke service pertama jika ada
    if (widget.services.isNotEmpty) {
      _selectedService = widget.services.first;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
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
        const SnackBar(
          content: Text('Pilih jam'),
          backgroundColor: Colors.red,
        ),
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

    final scheduleAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Format ke Y-m-d H:i:s untuk backend
    final scheduleAtFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduleAt);

    final request = CreateOrderRequest(
      providerId: widget.providerId,
      categoryId: widget.categoryId,
      providerServiceId: _selectedService!.id,
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      scheduleAt: scheduleAtFormatted,
      estimatedPrice: _selectedService!.basePrice,
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
      Navigator.of(context).pop();
    } else {
      final errorMsg =
          ref.read(createOrderControllerProvider).errorMessage ?? 'Order gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
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
      body: SingleChildScrollView(
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
                      child: Text('${service.name} - Rp${service.basePrice}/${service.priceUnit}'),
                    );
                  }).toList(),
                  onChanged: (ProviderService? newService) {
                    setState(() => _selectedService = newService);
                  },
                )
              else
                const Text('Tidak ada layanan tersedia'),
              const SizedBox(height: 24),

              // Alamat
              AppTextField(
                controller: _addressCtrl,
                label: 'Alamat Lokasi',
                maxLines: 3,
                prefixIcon: const Icon(Icons.location_on),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Alamat wajib diisi';
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
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
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
    );
  }
}
