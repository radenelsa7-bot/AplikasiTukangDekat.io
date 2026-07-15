import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'provider_services_page.dart';

final providerDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getProviderDashboard();
});

class ProviderDashboardPage extends ConsumerWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;

  const ProviderDashboardPage({
    super.key,
    required this.onOpenOrders,
    required this.onOpenAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(providerDashboardProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.orange,
        onRefresh: () async => ref.refresh(providerDashboardProvider.future),
        child: dashboard.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.orange)),
          error: (err, st) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text('Gagal memuat dashboard provider: $err', textAlign: TextAlign.center),
            ],
          ),
          data: (data) {
            final balance = int.tryParse(data['balance']?.toString() ?? '0') ?? 0;
            final activeOrders = data['active_orders'] ?? 0;
            final completedOrders = data['completed_orders'] ?? 0;
            final transactions = (data['transactions'] as List?) ?? [];

            return _DashboardContent(
              balance: balance,
              activeOrders: activeOrders,
              completedOrders: completedOrders,
              transactions: transactions,
              currency: currency,
              onOpenOrders: onOpenOrders,
              onOpenAccount: onOpenAccount,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final int balance;
  final int activeOrders;
  final int completedOrders;
  final List transactions;
  final NumberFormat currency;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;

  const _DashboardContent({
    required this.balance,
    required this.activeOrders,
    required this.completedOrders,
    required this.transactions,
    required this.currency,
    required this.onOpenOrders,
    required this.onOpenAccount,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Show footer when near bottom, hide when scrolling away
        if (notification.metrics.extentAfter < 50 && !_showFooter) {
          setState(() => _showFooter = true);
        } else if (notification.metrics.extentAfter > 100 && _showFooter) {
          setState(() => _showFooter = false);
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Provider', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  widget.currency.format(widget.balance),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(label: 'Order aktif', value: '${widget.activeOrders}'),
                    _MetricChip(label: 'Selesai', value: '${widget.completedOrders}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pesanan',
                  onTap: () async {
                    // Provider wajib aktifkan GPS saat menerima pesanan.
                    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi wajib aktif untuk menerima pesanan (GPS tidak aktif).'),
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
                          content: Text('Lokasi wajib aktif untuk menerima pesanan (izin lokasi belum diberikan).'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                      return;
                    }

                    widget.onOpenOrders();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.build_rounded,
                  label: 'Layanan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProviderServicesPage()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.person_rounded,
                  label: 'Akun',
                  onTap: widget.onOpenAccount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Transaksi Terbaru',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (widget.transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Belum ada transaksi masuk')),
            )
          else
            ...widget.transactions.map((item) {
              final tx = Map<String, dynamic>.from(item);
              final amount = int.tryParse(tx['provider_payout']?.toString() ?? tx['amount']?.toString() ?? '0') ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.payments_outlined, color: AppTheme.success),
                ),
                title: Text(tx['payment_type']?.toString() ?? 'Pembayaran'),
                subtitle: Text(tx['status']?.toString() ?? '-'),
                trailing: Text(widget.currency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }),
          const SizedBox(height: 24),
          if (_showFooter) const _DashboardFooter(),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.orange),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'TukangDekat Provider - kelola pesanan, laporan, dan transaksi dari satu tempat.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.grey600, fontSize: 12),
        ),
      ),
    );
  }
}
