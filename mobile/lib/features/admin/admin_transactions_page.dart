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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monitoring Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip('Semua', _statusFilter == null, () => setState(() => _statusFilter = null)),
                    _buildFilterChip('Lunas', _statusFilter == 'PAID', () => setState(() => _statusFilter = 'PAID')),
                    _buildFilterChip('Pending', _statusFilter == 'PENDING', () => setState(() => _statusFilter = 'PENDING')),
                    const SizedBox(width: 4),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppTheme.grey200,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(summary),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('Daftar Transaksi (${payments.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      if (payments.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Tidak ada transaksi',
                                style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ...payments.map((p) => _TransactionCard(payment: p)),
                      const SizedBox(height: 8),
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
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.grey600,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.orange,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.grey200),
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 360 ? 2 : 1);
        final childAspectRatio = constraints.maxWidth > 600 ? 2.2 : (constraints.maxWidth > 360 ? 2.0 : 1.8);
        final spacing = constraints.maxWidth > 360 ? 10.0 : 8.0;
        
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
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: items.map((item) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$4, size: 16, color: item.$3),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.$1, 
                        style: const TextStyle(fontSize: 10, color: AppTheme.grey600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    item.$2, 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: item.$3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Status Icon, Order Info, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isPaid ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle : Icons.schedule,
                        color: isPaid ? AppTheme.success : AppTheme.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Order code and type badge
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Flexible(
                                child: Text(
                                  'Order ${payment['order_code'] ?? '#${payment['order_id']}'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (type == 'DP' ? AppTheme.info : AppTheme.warning).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type, 
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: type == 'DP' ? AppTheme.info : AppTheme.warning),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Customer and provider info
                          Text(
                            '${payment['customer_name'] ?? '-'} → ${payment['provider_name'] ?? '-'}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.grey600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Date/Time
                          Text(
                            payment['paid_at'] ?? payment['created_at'] ?? '',
                            style: const TextStyle(fontSize: 10, color: AppTheme.grey400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount and status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _formatCurrency(payment['amount']),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPaid ? AppTheme.success : AppTheme.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPaid ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPaid ? 'Lunas' : status,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isPaid ? AppTheme.success : AppTheme.warning),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
