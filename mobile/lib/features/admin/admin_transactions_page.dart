import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';

final adminPaymentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminPayments();
});

class AdminTransactionsPage extends ConsumerStatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  ConsumerState<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends ConsumerState<AdminTransactionsPage> {
  String? _statusFilter;
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monitoring Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', _statusFilter == null, () => setState(() => _statusFilter = null)),
                    _buildFilterChip('Lunas', _statusFilter == 'PAID', () => setState(() => _statusFilter = 'PAID')),
                    _buildFilterChip('Pending', _statusFilter == 'PENDING', () => setState(() => _statusFilter = 'PENDING')),
                    const SizedBox(width: 12),
                    _buildFilterChip('DP', _typeFilter == 'DP', () => setState(() => _typeFilter = _typeFilter == 'DP' ? null : 'DP')),
                    _buildFilterChip('Final', _typeFilter == 'FINAL', () => setState(() => _typeFilter = _typeFilter == 'FINAL' ? null : 'FINAL')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => ref.refresh(adminPaymentsProvider), child: const Text('Coba Lagi')),
                ],
              ),
            ),
            data: (data) {
              final summary = Map<String, dynamic>.from(data['summary'] ?? {});
              final allPayments = List<Map<String, dynamic>>.from(
                (data['payments'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
              );

              // Filter locally
              final payments = allPayments.where((p) {
                if (_statusFilter != null && p['status'] != _statusFilter) return false;
                if (_typeFilter != null && p['payment_type'] != _typeFilter) return false;
                return true;
              }).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminPaymentsProvider),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(summary),
                      const SizedBox(height: 16),
                      Text('Daftar Transaksi (${payments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (payments.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Tidak ada transaksi')))),
                      ...payments.map((p) => _TransactionCard(payment: p)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.grey600)),
        selected: isSelected,
        selectedColor: AppTheme.orange,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.grey200),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final items = [
          ('Total Pendapatan', _formatCurrency(summary['total_amount']), AppTheme.success, Icons.account_balance_wallet),
          ('Total DP', _formatCurrency(summary['total_dp']), AppTheme.info, Icons.payment),
          ('Total Pelunasan', _formatCurrency(summary['total_final']), AppTheme.warning, Icons.payments),
          ('Jumlah Transaksi', '${summary['total_transactions'] ?? 0}', AppTheme.navy, Icons.receipt),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: items.map((item) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(item.$4, size: 18, color: item.$3),
                    const SizedBox(width: 6),
                    Text(item.$1, style: const TextStyle(fontSize: 11, color: AppTheme.grey600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: item.$3)),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  static String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    final formatted = num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _TransactionCard({required this.payment});

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
    final status = payment['status'] ?? '';
    final isPaid = status == 'PAID';
    final type = payment['payment_type'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPaid ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.schedule,
                color: isPaid ? AppTheme.success : AppTheme.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Order ${payment['order_code'] ?? '#${payment['order_id']}'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (type == 'DP' ? AppTheme.info : AppTheme.warning).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: type == 'DP' ? AppTheme.info : AppTheme.warning)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${payment['customer_name'] ?? '-'} → ${payment['provider_name'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                  Text(payment['paid_at'] ?? payment['created_at'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(payment['amount']),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isPaid ? AppTheme.success : AppTheme.navy),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPaid ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPaid ? 'Lunas' : status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPaid ? AppTheme.success : AppTheme.warning),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
