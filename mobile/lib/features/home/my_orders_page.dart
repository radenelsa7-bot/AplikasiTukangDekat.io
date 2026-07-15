import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';
import 'order_detail_page.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  static const _activeOrderStatuses = {
    'CREATED',
    'ACCEPTED',
    'IN_PROGRESS',
    'COMPLETED',
  };

  Future<void> _openStatusFilter(BuildContext context, WidgetRef ref) async {
    final current = ref.read(myOrdersStatusFilterProvider);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.60,
          minChildSize: 0.35,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  ListTile(
                    title: const Text('Semua'),
                    leading: const Icon(Icons.filter_alt_off),
                    trailing: current == null ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(sheetContext).pop(null),
                  ),
                  const Divider(height: 1),
                  ...const [
                    ('ACTIVE', 'Belum selesai'),
                    ('CREATED', 'Menunggu konfirmasi'),
                    ('ACCEPTED', 'Diterima'),
                    ('IN_PROGRESS', 'Dikerjakan'),
                    ('COMPLETED', 'Menunggu pelunasan'),
                    ('CLOSED', 'Selesai & lunas'),
                    ('CANCELLED', 'Dibatalkan'),
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
                ],
              ),
            );
          },
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
                  color: AppTheme.danger.withValues(alpha: 0.1),
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
            : orders
                  .where(
                    (order) => _matchesStatusFilter(order.status, statusFilter),
                  )
                  .toList();

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
                      color: AppTheme.orange.withValues(alpha: 0.08),
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
                        ? 'Tidak ada pesanan dengan status ${_statusLabel(statusFilter).toLowerCase()}'
                        : authState.userRole == 'PROVIDER'
                        ? 'Order dari pelanggan akan muncul di sini'
                        : 'Pesan jasa teknisi dari halaman Beranda',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                  ),
                  if (statusFilter != null) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _openStatusFilter(context, ref),
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Ubah Filter'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref
                                  .read(myOrdersStatusFilterProvider.notifier)
                                  .state =
                              null,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Tampilkan Semua Pesanan'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.orange,
          onRefresh: () async => ref.refresh(myOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            itemCount: filteredOrders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.navy,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.navy.withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              authState.userRole == 'PROVIDER'
                                  ? 'Order Masuk'
                                  : 'Pesanan Saya',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredOrders.length} pesanan',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openStatusFilter(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.1),
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
                      ),
                    ],
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
            color: Colors.black.withValues(alpha: 0.03),
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
                        color: statusColor.withValues(alpha: 0.1),
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
                        color: statusColor.withValues(alpha: 0.1),
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
      case 'ACTIVE':
        return 'Belum selesai';
      case 'CREATED':
        return 'Menunggu konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'IN_PROGRESS':
        return 'Dikerjakan';
      case 'COMPLETED':
        return 'Menunggu pelunasan';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'CLOSED':
        return 'Selesai & lunas';
      default:
        return status;
    }
  }

  String _statusLabel(String status) => _getStatusLabel(status);

  bool _matchesStatusFilter(String orderStatus, String filter) {
    if (filter == 'ACTIVE') return _activeOrderStatuses.contains(orderStatus);
    return orderStatus == filter;
  }
}
