import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/models/order_model.dart';
import '../../shared/widgets/location_map_preview.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;
  final bool autoOpenQris;
  final int? autoPaymentId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.autoOpenQris = false,
    this.autoPaymentId,
  });

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _autoOpened = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      body: orderAsync.when(
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
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat detail order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  style: const TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        data: (order) {
          // Auto-open QRIS dialog if requested via navigation flags (only once)
          if (widget.autoOpenQris && !_autoOpened) {
            _autoOpened = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final api = ref.read(apiServiceProvider);
                if (widget.autoPaymentId != null) {
                  final q = await api.generateQRIS(widget.autoPaymentId!);
                  if (context.mounted) {
                    _showQrisDialog(
                      context,
                      ref,
                      q,
                      order.id,
                      widget.autoPaymentId!,
                    );
                  }
                  return;
                }

                // If no payment id, try to find unpaid payment on order
                PaymentData? unpaid;
                if (order.payments.isNotEmpty) {
                  unpaid = order.payments.firstWhere(
                    (p) => p.status == 'UNPAID' || p.status == 'PENDING',
                    orElse: () => order.payments.first,
                  );
                } else {
                  unpaid = null;
                }
                if (unpaid != null) {
                  final q = await api.generateQRIS(unpaid.id);
                  if (context.mounted) {
                    _showQrisDialog(context, ref, q, order.id, unpaid.id);
                  }
                }
              } catch (_) {
                // ignore errors silently
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(context, order),
                const SizedBox(height: 16),
                _buildInfoCard(context, order),
                const SizedBox(height: 16),
                _buildTrackingCard(context, order),
                const SizedBox(height: 16),
                if (order.attachments.isNotEmpty)
                  _buildAttachmentsCard(context, order),
                if (order.attachments.isNotEmpty) const SizedBox(height: 16),
                _buildPricingCard(context, order),
                const SizedBox(height: 16),
                if (order.payments.isNotEmpty)
                  _buildPaymentsCard(context, ref, order),
                if (order.payments.isNotEmpty) const SizedBox(height: 16),
                _buildProviderActions(context, ref, order),
                const SizedBox(height: 16),
                _buildCustomerActions(context, ref, order),
                const SizedBox(height: 16),
                _buildReviewSection(context, ref, order),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, OrderData order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, OrderData order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppTheme.navy),
              const SizedBox(width: 8),
              Text(
                'Informasi Order',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'Alamat', order.address),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Jadwal',
            DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(DateTime.parse(order.scheduleAt)),
          ),
          if (order.notes != null && order.notes!.isNotEmpty)
            _buildInfoRow(Icons.note_outlined, 'Catatan', order.notes!),
          if (order.damageDescription != null && order.damageDescription!.isNotEmpty)
            _buildInfoRow(Icons.build_circle_outlined, 'Kondisi', order.damageDescription!),
          if (order.queueNote != null && order.queueNote!.isNotEmpty)
            _buildInfoRow(Icons.info_outline, 'Info Antrian', order.queueNote!),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, OrderData order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, size: 18, color: AppTheme.navy),
              const SizedBox(width: 8),
              Text(
                'Tracking Lokasi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LocationMapPreview(
            customerLatitude: order.customerLatitude,
            customerLongitude: order.customerLongitude,
            providerLatitude: order.providerLatitude,
            providerLongitude: order.providerLongitude,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.grey600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(BuildContext context, OrderData order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, size: 18, color: AppTheme.navy),
              const SizedBox(width: 8),
              Text(
                'Foto Pesanan',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final att = order.attachments[index];
                final url = att.publicUrl ?? att.fileUrl ?? '';
                if (url.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () async {
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 76,
                                color: AppTheme.grey100,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppTheme.grey600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _attachmentPurposeLabel(att.purpose),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _attachmentPurposeLabel(String purpose) {
    switch (purpose) {
      case 'PROVIDER_INITIAL':
        return 'Kondisi awal';
      case 'PROVIDER_FINAL':
        return 'Kondisi akhir';
      case 'PROVIDER_RECEIPT':
        return 'Kuitansi';
      default:
        return 'Kerusakan';
    }
  }

  Widget _buildPricingCard(BuildContext context, OrderData order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: 8),
              Text(
                'Rincian Biaya',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga Estimasi',
                style: TextStyle(color: AppTheme.grey600),
              ),
              Text(
                currencyFormat.format(order.estimatedPrice),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (order.estimatedPriceMin != null && order.estimatedPriceMax != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Range kondisi',
                    style: TextStyle(color: AppTheme.grey600),
                  ),
                ),
                Text(
                  '${currencyFormat.format(order.estimatedPriceMin)} - ${currencyFormat.format(order.estimatedPriceMax)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (order.finalPrice != null) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harga Final',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  currencyFormat.format(order.finalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsCard(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_outlined,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: 8),
              Text(
                'Pembayaran',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.payments.map((payment) {
            final isPaid =
                payment.status == 'PAID' || payment.status == 'COMPLETED';
            final isCancelled = order.status == 'CANCELLED';
            final statusColor = isPaid
                ? AppTheme.success
                : (isCancelled ? AppTheme.danger : AppTheme.warning);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle : Icons.pending,
                              size: 16,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.paymentType == 'DP'
                                    ? 'Down Payment (50%)'
                                    : 'Pelunasan (50%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPaid
                                    ? 'Lunas'
                                    : (isCancelled
                                          ? 'Dibatalkan'
                                          : 'Belum Dibayar'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        currencyFormat.format(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (!isPaid &&
                      (payment.status == 'UNPAID' ||
                          payment.status == 'PENDING') &&
                      ![
                        'CANCELLED',
                        'CLOSED',
                        'COMPLETED',
                      ].contains(order.status)) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (ctx) {
                        final authState = ref.watch(authControllerProvider);
                        if (authState.userRole == 'CUSTOMER') {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_2, size: 18),
                              label: const Text('Bayar Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final api = ref.read(apiServiceProvider);
                                try {
                                  final qris = await api.generateQRIS(
                                    payment.id,
                                  );
                                  if (ctx.mounted) {
                                    _showQrisDialog(
                                      ctx,
                                      ref,
                                      qris,
                                      order.id,
                                      payment.id,
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal generate QRIS: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final authState = ref.watch(authControllerProvider);

    if (authState.userRole != 'CUSTOMER') return const SizedBox.shrink();
    if (order.status == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 18,
                  color: AppTheme.navy,
                ),
                SizedBox(width: 8),
                Text(
                  'Beri Ulasan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Order sudah selesai dan menunggu pelunasan final. Setelah pelunasan, order akan ditutup dan Anda dapat memberikan ulasan.',
              style: TextStyle(fontSize: 13, color: AppTheme.grey600),
            ),
          ],
        ),
      );
    }

    if (order.status != 'CLOSED') return const SizedBox.shrink();

    final reviewAsync = ref.watch(orderReviewProvider(order.id));

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (review) {
        if (review != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ulasan Anda',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 22,
                    );
                  }),
                ),
                if ((review.comment ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    review.comment!,
                    style: const TextStyle(color: AppTheme.grey600),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: AppTheme.navy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Beri Ulasan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Bagikan pengalaman Anda.',
                style: TextStyle(fontSize: 13, color: AppTheme.grey600),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: order.status == 'CLOSED'
                      ? () => _showReviewDialog(context, ref, order.id)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order harus selesai untuk memberi ulasan',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Tulis Ulasan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderActions(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final authState = ref.watch(authControllerProvider);
    final actionState = ref.watch(orderActionControllerProvider);

    if (authState.userRole != 'PROVIDER') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: 8),
              Text(
                'Tindakan',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (order.status == 'CREATED') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Terima Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(orderActionControllerProvider.notifier)
                            .respondToOrder(order.id, 'accept');
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order diterima!')),
                          );
                          ref.invalidate(orderDetailProvider(order.id));
                        }
                      },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Tolak Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(orderActionControllerProvider.notifier)
                            .respondToOrder(order.id, 'reject');
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order ditolak')),
                          );
                          ref.invalidate(orderDetailProvider(order.id));
                        }
                      },
              ),
            ),
          ] else if (order.status == 'ACCEPTED') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Mulai Pekerjaan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(orderActionControllerProvider.notifier)
                            .startWork(order.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pekerjaan dimulai')),
                          );
                          ref.invalidate(orderDetailProvider(order.id));
                        } else if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                actionState.errorMessage ??
                                    'DP harus dibayar terlebih dahulu',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
          ] else if (order.status == 'IN_PROGRESS') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Selesaikan Pekerjaan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: actionState.isLoading
                    ? null
                    : () => _showFinalPriceDialog(context, ref, order),
              ),
            ),
          ],
          if (actionState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.orange,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerActions(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final authState = ref.watch(authControllerProvider);
    final actionState = ref.watch(orderActionControllerProvider);

    if (authState.userRole != 'CUSTOMER') return const SizedBox.shrink();

    final cancellable = [
      'CREATED',
      'ACCEPTED',
      'IN_PROGRESS',
    ].contains(order.status);
    final approvalPending =
        order.status == 'COMPLETED' &&
        order.finalPriceApprovalStatus == 'PENDING';
    if (!cancellable && !approvalPending) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: 8),
              Text(
                'Tindakan',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (approvalPending) ...[
            const Text(
              'Provider sudah mengirim harga final. Setujui untuk menerbitkan tagihan pelunasan.',
              style: TextStyle(fontSize: 13, color: AppTheme.grey600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: actionState.isLoading
                        ? null
                        : () => _decideFinalPrice(
                            context,
                            ref,
                            order,
                            'reject',
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Setuju'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: actionState.isLoading
                        ? null
                        : () => _decideFinalPrice(
                            context,
                            ref,
                            order,
                            'approve',
                          ),
                  ),
                ),
              ],
            ),
          ],
          if (cancellable) ...[
            if (approvalPending) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Batalkan Pesanan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: actionState.isLoading
                    ? null
                    : () => _showCancelDialog(context, ref, order),
              ),
            ),
          ],
          if (actionState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.orange,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _decideFinalPrice(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
    String action,
  ) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.decideFinalPrice(orderId: order.id, action: action);
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(myOrdersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Harga final disetujui. Tagihan pelunasan sudah dibuat.'
                : 'Harga final ditolak.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses harga final: $e')),
      );
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, OrderData order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Apakah Anda yakin ingin membatalkan pesanan ini?',
              style: TextStyle(fontSize: 13, color: AppTheme.grey600),
            ),
            if (order.status == 'IN_PROGRESS') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pekerjaan sedang berjalan. Pembatalan mungkin dikenakan biaya.',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Alasan pembatalan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim();
              final success = await ref
                  .read(orderActionControllerProvider.notifier)
                  .cancelOrder(order.id, reason: reason);
              if (context.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pesanan berhasil dibatalkan'),
                    ),
                  );
                  ref.invalidate(orderDetailProvider(order.id));
                } else {
                  final errorMsg = ref
                      .read(orderActionControllerProvider)
                      .errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg ?? 'Gagal membatalkan pesanan'),
                    ),
                  );
                }
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showFinalPriceDialog(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final controller = TextEditingController(
      text: order.estimatedPrice.toString(),
    );
    final initialPhotos = <XFile>[];
    final finalPhotos = <XFile>[];
    final receiptPhotos = <XFile>[];
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickInto(List<XFile> target) async {
            final images = await picker.pickMultiImage();
            if (images.isNotEmpty) {
              setDialogState(() => target.addAll(images));
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Harga Final',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan harga akhir dan laporan foto setelah pekerjaan selesai',
                    style: TextStyle(fontSize: 13, color: AppTheme.grey600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildReportPicker('Foto kondisi awal', initialPhotos, () => pickInto(initialPhotos)),
                  _buildReportPicker('Foto kondisi akhir', finalPhotos, () => pickInto(finalPhotos)),
                  _buildReportPicker('Foto kuitansi pembelian', receiptPhotos, () => pickInto(receiptPhotos)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final finalPrice = int.tryParse(controller.text) ?? 0;
                  if (finalPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harga tidak valid')),
                    );
                    return;
                  }
                  if (initialPhotos.isEmpty || finalPhotos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto kondisi awal dan akhir wajib diisi')),
                    );
                    return;
                  }

                  final success = await ref
                      .read(orderActionControllerProvider.notifier)
                      .completeOrder(
                        order.id,
                        finalPrice,
                        initialConditionPhotos: await _toMultipart(initialPhotos),
                        finalConditionPhotos: await _toMultipart(finalPhotos),
                        receiptPhotos: await _toMultipart(receiptPhotos),
                      );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pekerjaan selesai!')),
                      );
                      ref.invalidate(orderDetailProvider(order.id));
                    }
                  }
                },
                child: const Text('Konfirmasi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportPicker(String label, List<XFile> files, VoidCallback onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label (${files.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<List<MultipartFile>> _toMultipart(List<XFile> files) async {
    final result = <MultipartFile>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final lower = file.name.toLowerCase();
      final mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      result.add(
        MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: MediaType.parse(mime),
        ),
      );
    }
    return result;
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, int orderId) {
    final commentController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Tulis Ulasan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Beri rating',
                      style: TextStyle(fontSize: 13, color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => selectedRating = starValue),
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ceritakan pengalaman Anda...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(apiServiceProvider)
                          .createReview(
                            orderId: orderId,
                            rating: selectedRating,
                            comment: commentController.text.trim().isEmpty
                                ? null
                                : commentController.text.trim(),
                          );
                      ref.invalidate(orderReviewProvider(orderId));
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ulasan berhasil dikirim'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
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
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'IN_PROGRESS':
        return 'Sedang Dikerjakan';
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

  void _showQrisDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> qrisData,
    int orderId,
    int paymentId,
  ) {
    final qrisImage = qrisData['qris_image'] as String?;
    final checkoutUrl = qrisData['checkout_url'] as String?;
    final qrisHint = qrisData['qris_hint'] as String?;
    final amount = qrisData['amount'];
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    Uint8List? imageBytes;
    if (qrisImage != null && qrisImage.startsWith('data:image')) {
      final parts = qrisImage.split(',');
      if (parts.length == 2) {
        try {
          imageBytes = base64Decode(parts[1]);
        } catch (_) {
          imageBytes = null;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Auto-open checkout URL on Web platform after dialog appears
        if (qrisHint == 'open_checkout_url' &&
            checkoutUrl != null &&
            checkoutUrl.isNotEmpty &&
            kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final uri = Uri.tryParse(checkoutUrl);
            if (uri != null) {
              // Use externalApplication on Web to prevent blank screen
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2, color: AppTheme.success),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pembayaran QRIS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (amount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currencyFormat.format(
                        amount is int
                            ? amount
                            : int.tryParse(amount.toString()) ?? 0,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(imageBytes, width: 200, height: 200),
                  ),
                if (imageBytes == null && qrisData['qris_code'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      qrisData['qris_code'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                if (checkoutUrl != null && checkoutUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Buka Halaman Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.info,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.tryParse(checkoutUrl);
                        if (uri != null) {
                          // Use externalApplication for Web, inAppWebView for mobile
                          final launchMode = kIsWeb
                              ? LaunchMode.externalApplication
                              : LaunchMode.inAppWebView;
                          await launchUrl(uri, mode: launchMode);
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Scan QRIS atau buka halaman pembayaran untuk menyelesaikan transaksi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.grey600),
                ),
              ],
            ),
          ),
          actions: [
            if (!kIsWeb)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final result = await ref
                      .read(apiServiceProvider)
                      .confirmPayment(paymentId);
                  ref.invalidate(orderDetailProvider(orderId));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    final midtransStatus = result['midtrans_status'];
                    if (midtransStatus != null &&
                        midtransStatus != 'settlement' &&
                        midtransStatus != 'capture') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Status pembayaran: $midtransStatus. Silakan selesaikan pembayaran di Midtrans.',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran berhasil dikonfirmasi!'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal konfirmasi: $e')),
                    );
                  }
                }
              },
              child: const Text('Sudah Dibayar'),
            ),
          ],
        );
      },
    );
  }
}
