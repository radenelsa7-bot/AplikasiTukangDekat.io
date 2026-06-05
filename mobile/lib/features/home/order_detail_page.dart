import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/models/order_model.dart';
import '../auth/auth_controller.dart';
import 'order_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  final int orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Order')),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
        data: (order) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Order',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order info
                _buildSection(
                  context,
                  'Informasi Order',
                  [
                    _buildInfo('Kode Order', order.orderCode),
                    _buildInfo('Alamat', order.address),
                    _buildInfo(
                      'Jadwal',
                      DateFormat('dd MMM yyyy HH:mm')
                        .format(DateTime.parse(order.scheduleAt)),
                    ),
                    if (order.notes != null && order.notes!.isNotEmpty)
                      _buildInfo('Catatan', order.notes!),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing
                _buildSection(
                  context,
                  'Pricing',
                  [
                    _buildInfo(
                      'Harga Estimasi',
                      'Rp${order.estimatedPrice}',
                    ),
                    if (order.finalPrice != null)
                      _buildInfo(
                        'Harga Final',
                        'Rp${order.finalPrice}',
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payments
                if (order.payments.isNotEmpty)
                  _buildSection(
                    context,
                    'Pembayaran',
                    [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.payments.length,
                        itemBuilder: (context, index) {
                          final payment = order.payments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(payment.paymentType),
                                      Text(
                                        'Rp${payment.amount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status: ${payment.status}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: payment.status == 'COMPLETED'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                      if (payment.paidAt != null)
                                        Text(
                                          DateFormat('dd MMM HH:mm')
                                              .format(DateTime.parse(
                                                  payment.paidAt!)),
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                      // If user is customer and payment unpaid, show Pay button
                                      Builder(builder: (ctx) {
                                        final authState = ref.watch(authControllerProvider);
                                        if (authState.userRole == 'CUSTOMER' && payment.status == 'UNPAID') {
                                          return ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                              textStyle: const TextStyle(fontSize: 12),
                                            ),
                                            onPressed: () async {
                                              final api = ref.read(apiServiceProvider);
                                              try {
                                                final qris = await api.generateQRIS(payment.id);
                                                if (ctx.mounted) {
                                                  _showQrisDialog(ctx, ref, qris, order.id, payment.id);
                                                }
                                              } catch (e) {
                                                if (ctx.mounted) {
                                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                                    SnackBar(content: Text('Gagal generate QRIS: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('Bayar'),
                                          );
                                        }

                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Provider action buttons
                _buildProviderActions(context, ref, order),
                const SizedBox(height: 16),

                // Review section for customers
                _buildReviewSection(context, ref, order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    WidgetRef ref,
    OrderData order,
  ) {
    final authState = ref.watch(authControllerProvider);

    if (authState.userRole != 'CUSTOMER') {
      return const SizedBox.shrink();
    }

    if (order.status != 'COMPLETED' && order.status != 'CLOSED') {
      return const SizedBox.shrink();
    }

    final reviewAsync = ref.watch(orderReviewProvider(order.id));

    return reviewAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, st) => const SizedBox.shrink(),
      data: (review) {
        if (review != null) {
          return _buildSection(
            context,
            'Ulasan Anda',
            [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 8),
              if ((review.comment ?? '').isNotEmpty)
                _buildInfo('Komentar', review.comment!),
            ],
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beri Ulasan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bagikan pengalaman Anda setelah pekerjaan selesai.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(context, ref, order.id),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Tulis Ulasan'),
                  ),
                ),
              ],
            ),
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

    // Only show for providers
    if (authState.userRole != 'PROVIDER') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tindakan Provider',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (order.status == 'CREATED') ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      // ignore: unused_result
                      ref.refresh(orderDetailProvider(order.id));
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(actionState.errorMessage ?? 'Error'),
                        ),
                      );
                    }
                  },
            child: actionState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Terima Order',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      // ignore: unused_result
                      ref.refresh(orderDetailProvider(order.id));
                    }
                  },
            child: const Text(
              'Tolak Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ] else if (order.status == 'ACCEPTED') ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      // ignore: unused_result
                      ref.refresh(orderDetailProvider(order.id));
                    }
                  },
            child: const Text(
              'Mulai Pekerjaan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ] else if (order.status == 'IN_PROGRESS') ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: actionState.isLoading
                ? null
                : () async {
                    // Show dialog untuk input final price
                    final controller = TextEditingController(
                      text: order.estimatedPrice.toString(),
                    );
                    
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Harga Final'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Masukkan harga final (Rp)',
                            hintText: '0',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final finalPrice = int.tryParse(controller.text) ?? 0;
                              if (finalPrice <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Harga tidak valid')),
                                );
                                return;
                              }
                              
                              final success = await ref
                                  .read(orderActionControllerProvider.notifier)
                                  .completeOrder(order.id, finalPrice);
                              
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pekerjaan selesai')),
                                  );
                                  // ignore: unused_result
                                  ref.refresh(orderDetailProvider(order.id));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(actionState.errorMessage ?? 'Error'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Selesai'),
                          ),
                        ],
                      ),
                    );
                  },
            child: const Text(
              'Selesaikan Pekerjaan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) {
    final commentController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tulis Ulasan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rating'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              selectedRating = starValue;
                            });
                          },
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Komentar (opsional)',
                        hintText: 'Ceritakan pengalaman Anda',
                        border: OutlineInputBorder(),
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
                TextButton(
                  onPressed: () async {
                    try {
                      await ref.read(apiServiceProvider).createReview(
                            orderId: orderId,
                            rating: selectedRating,
                            comment: commentController.text.trim().isEmpty
                                ? null
                                : commentController.text.trim(),
                          );
                      // ignore: unused_result
                      ref.refresh(orderReviewProvider(orderId));
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ulasan berhasil dikirim')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal kirim ulasan: $e')),
                        );
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

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

  void _showQrisDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> qrisData, int orderId, int paymentId) {
    final qrisImage = qrisData['qris_image'] as String?;
    final checkoutUrl = qrisData['checkout_url'] as String?;
    final qrisHint = qrisData['qris_hint'] as String?;
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
      builder: (ctx) {
        // If gateway suggests opening checkout URL, trigger opening after frame rendered
              if (qrisHint == 'open_checkout_url' && checkoutUrl != null && checkoutUrl.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final uri = Uri.tryParse(checkoutUrl);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
            }
          });
        }

        return AlertDialog(
        title: const Text('QRIS Pembayaran'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null)
                Image.memory(imageBytes, width: 200, height: 200),
              if (imageBytes == null && qrisData['qris_code'] != null)
                SelectableText(qrisData['qris_code']),
              if (checkoutUrl != null && checkoutUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectableText(
                  checkoutUrl,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              Text('Jumlah: Rp${qrisData['amount'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          if (checkoutUrl != null && checkoutUrl.isNotEmpty)
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(checkoutUrl);
                if (uri == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL pembayaran tidak valid')),
                  );
                  return;
                }

                final opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal membuka halaman pembayaran')),
                  );
                }
              },
              child: const Text('Buka Pembayaran'),
            ),
          TextButton(
                onPressed: () async {
              // Simulate gateway callback for testing
              try {
                await ref.read(apiServiceProvider).simulatePaymentCallback(paymentId);
                // ignore: unused_result
                ref.refresh(orderDetailProvider(orderId));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pembayaran disimulasikan sebagai berhasil')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal simulasi pembayaran: $e')),
                  );
                }
              }
            },
            child: const Text('Saya sudah bayar (simulasi)'),
          ),
        ],
      ),
    );
  }
}
