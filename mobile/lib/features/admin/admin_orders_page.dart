import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';

final adminOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      status,
    ) async {
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
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Text(
                'Monitoring Pesanan',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    hint: Text(
                      'Semua Status',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Semua Status'),
                      ),
                      DropdownMenuItem(value: 'CREATED', child: Text('Baru')),
                      DropdownMenuItem(
                        value: 'ACCEPTED',
                        child: Text('Diterima'),
                      ),
                      DropdownMenuItem(
                        value: 'IN_PROGRESS',
                        child: Text('Dikerjakan'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('Selesai'),
                      ),
                      DropdownMenuItem(value: 'CLOSED', child: Text('Ditutup')),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Dibatalkan'),
                      ),
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
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () =>
                        ref.refresh(adminOrdersProvider(_statusFilter)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64.sp,
                        color: AppTheme.grey400.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 12.h),
                      const Text(
                        'Tidak ada pesanan',
                        style: TextStyle(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(adminOrdersProvider(_statusFilter)),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
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
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['order_code'] ?? '#${order['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        order['created_at'] ?? '',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.person,
                    'Customer',
                    order['customer_name'] ?? '-',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInfoItem(
                    Icons.engineering,
                    'Provider',
                    order['provider_name'] ?? '-',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.payment,
                    'Estimasi',
                    _formatCurrency(order['estimated_price']),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Row(
                    children: [
                      _buildPaymentBadge('DP', order['dp_status']),
                      SizedBox(width: 6.w),
                      _buildPaymentBadge('Final', order['final_status']),
                    ],
                  ),
                ),
              ],
            ),
            if (order['address'] != null &&
                order['address'].toString().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14.sp, color: AppTheme.grey600),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      order['address'].toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
        Icon(icon, size: 14.sp, color: AppTheme.grey600),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, color: AppTheme.grey600),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String type, dynamic status) {
    final st = status?.toString() ?? 'PENDING';
    final color = st == 'PAID'
        ? AppTheme.success
        : (st == 'PENDING' ? AppTheme.warning : AppTheme.grey400);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$type: $st',
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
