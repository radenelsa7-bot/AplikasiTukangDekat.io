import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';
import 'order_detail_page.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final authState = ref.watch(authControllerProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(myOrdersProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    authState.userRole == 'PROVIDER'
                        ? 'Tidak ada order masuk'
                        : 'Belum ada pemesanan',
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authState.userRole == 'PROVIDER'
                        ? 'Order Masuk'
                        : 'Pesanan Saya',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.userRole == 'PROVIDER'
                        ? 'Kelola order dari pelanggan'
                        : 'Riwayat pesanan Anda',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            final order = orders[index - 1];
            return _buildOrderCard(context, order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.receipt_long, color: statusColor),
        ),
        title: Text('Order #${order.orderCode}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (order.scheduleAt != null)
              Text(
                DateFormat(
                  'dd MMM yyyy HH:mm',
                ).format(DateTime.parse(order.scheduleAt)),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp${order.estimatedPrice ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(orderId: order.id),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CREATED':
        return Colors.blue;
      case 'ACCEPTED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
