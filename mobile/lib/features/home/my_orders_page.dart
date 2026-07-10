import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';
import 'order_detail_page.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  Future<void> _openStatusFilter(BuildContext context, WidgetRef ref) async {
    final current = ref.read(myOrdersStatusFilterProvider);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Semua'),
                leading: const Icon(Icons.filter_alt_off),
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(null),
              ),
              const Divider(height: 1),
              ...const [
                ('CREATED', 'Menunggu'),
                ('ACCEPTED', 'Diterima'),
                ('IN_PROGRESS', 'Dikerjakan'),
                ('COMPLETED', 'Selesai'),
                ('CANCELLED', 'Dibatalkan'),
                ('CLOSED', 'Ditutup'),
              ].map(
                (entry) => ListTile(
                  title: Text(entry.$2),
                  leading: const Icon(Icons.receipt_long),
                  trailing: current == entry.$1
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(entry.$1),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null || current != null) {
      ref.read(myOrdersStatusFilterProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final authState = ref.watch(authControllerProvider);
    final statusFilter = ref.watch(myOrdersStatusFilterProvider);

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.orange),
      ),
      error: (err, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gagal memuat data',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(myOrdersProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (orders) {
        final filteredOrders = statusFilter == null
            ? orders
            : orders.where((order) => order.status == statusFilter).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      authState.userRole == 'PROVIDER'
                          ? Icons.inbox_rounded
                          : Icons.shopping_bag_outlined,
                      size: 56,
                      color: AppTheme.orange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusFilter != null
                        ? 'Tidak Ada Hasil Filter'
                        : authState.userRole == 'PROVIDER'
                        ? 'Belum Ada Order Masuk'
                        : 'Belum Ada Pesanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusFilter != null
                        ? 'Coba pilih status lain atau hapus filter'
                        : authState.userRole == 'PROVIDER'
                        ? 'Order dari pelanggan akan muncul di sini'
                        : 'Pesan jasa teknisi dari halaman Beranda',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.orange,
          onRefresh: () async => ref.refresh(myOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: filteredOrders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    );
                final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authState.userRole == 'PROVIDER'
                                          ? 'Order Masuk'
                                          : 'Pesanan Saya',
                                      style: titleStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${filteredOrders.length} pesanan',
                                      style: subtitleStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _openStatusFilter(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.filter_list,
                                        size: 16,
                                        color: AppTheme.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusFilter == null
                                            ? 'Semua'
                                            : _statusLabel(statusFilter),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              }
              final order = filteredOrders[index - 1];
              return _buildOrderCard(context, order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(orderId: order.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(order.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (order.scheduleAt != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.grey600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.parse(order.scheduleAt)),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      Text(
                        currencyFormat.format(order.estimatedPrice ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.attachments != null &&
                    order.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 2, right: 2),
                      itemCount: order.attachments.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final att = order.attachments[i];
                        final url = att.publicUrl ?? att.fileUrl ?? '';
                        if (url.isEmpty) return const SizedBox.shrink();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 120,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 120,
                              height: 100,
                              color: AppTheme.grey100,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppTheme.grey600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CREATED':
        return AppTheme.info;
      case 'ACCEPTED':
        return AppTheme.warning;
      case 'IN_PROGRESS':
        return const Color(0xFF8B5CF6);
      case 'COMPLETED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      case 'CLOSED':
        return AppTheme.grey600;
      default:
        return AppTheme.grey600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CREATED':
        return Icons.pending_outlined;
      case 'ACCEPTED':
        return Icons.check_circle_outline;
      case 'IN_PROGRESS':
        return Icons.construction;
      case 'COMPLETED':
        return Icons.task_alt;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      case 'CLOSED':
        return Icons.archive_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'CREATED':
        return 'Menunggu';
      case 'ACCEPTED':
        return 'Diterima';
      case 'IN_PROGRESS':
        return 'Dikerjakan';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'CLOSED':
        return 'Ditutup';
      default:
        return status;
    }
  }

  String _statusLabel(String status) => _getStatusLabel(status);
}
