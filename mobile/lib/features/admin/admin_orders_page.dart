import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';

final adminOrdersProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminOrders(status: status);
});

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_statusFilter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Monitoring Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('Semua Status', style: TextStyle(fontSize: 13)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Status')),
                      DropdownMenuItem(value: 'CREATED', child: Text('Baru')),
                      DropdownMenuItem(value: 'ACCEPTED', child: Text('Diterima')),
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Dikerjakan')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('Selesai')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('Ditutup')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Dibatalkan')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => ref.refresh(adminOrdersProvider(_statusFilter)), child: const Text('Coba Lagi')),
                ],
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.grey400.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('Tidak ada pesanan', style: TextStyle(color: AppTheme.grey600)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminOrdersProvider(_statusFilter)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  static const _statusColors = {
    'CREATED': AppTheme.info,
    'ACCEPTED': AppTheme.warning,
    'IN_PROGRESS': AppTheme.orange,
    'COMPLETED': AppTheme.success,
    'CLOSED': AppTheme.grey600,
    'CANCELLED': AppTheme.danger,
  };

  static const _statusLabels = {
    'CREATED': 'Baru',
    'ACCEPTED': 'Diterima',
    'IN_PROGRESS': 'Dikerjakan',
    'COMPLETED': 'Selesai',
    'CLOSED': 'Ditutup',
    'CANCELLED': 'Dibatalkan',
  };

  static const _statusIcons = {
    'CREATED': Icons.fiber_new,
    'ACCEPTED': Icons.thumb_up,
    'IN_PROGRESS': Icons.construction,
    'COMPLETED': Icons.check_circle,
    'CLOSED': Icons.lock,
    'CANCELLED': Icons.cancel,
  };

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    final formatted = num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? '';
    final color = _statusColors[status] ?? AppTheme.grey400;
    final icon = _statusIcons[status] ?? Icons.help;
    final label = _statusLabels[status] ?? status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['order_code'] ?? '#${order['id']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        order['created_at'] ?? '',
                        style: const TextStyle(fontSize: 11, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.person, 'Customer', order['customer_name'] ?? '-'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(Icons.engineering, 'Provider', order['provider_name'] ?? '-'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.payment, 'Estimasi', _formatCurrency(order['estimated_price'])),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      _buildPaymentBadge('DP', order['dp_status']),
                      const SizedBox(width: 6),
                      _buildPaymentBadge('Final', order['final_status']),
                    ],
                  ),
                ),
              ],
            ),
            if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.grey600),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order['address'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.grey600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.grey600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.grey600)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String type, dynamic status) {
    final st = status?.toString() ?? 'PENDING';
    final color = st == 'PAID' ? AppTheme.success : (st == 'PENDING' ? AppTheme.warning : AppTheme.grey400);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('$type: $st', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
