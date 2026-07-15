import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../../shared/widgets/location_map_preview.dart';
import 'catalog_providers.dart';
import 'create_order_page.dart';

class ProviderDetailPage extends ConsumerWidget {
  final int providerId;
  final int categoryId;

  const ProviderDetailPage({
    super.key,
    required this.providerId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerDetailProvider(providerId));
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Teknisi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: providerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (provider) {
          final isBusy = provider.availabilityStatus == 'BUSY';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 420;
                        final statusChip = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isBusy
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isBusy ? 'Sedang dipesan' : 'Tersedia',
                            style: TextStyle(
                              color: isBusy
                                  ? Colors.orange.shade800
                                  : Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (compact)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 34,
                                        child: Icon(Icons.person, size: 34),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.businessName,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      provider.avgRating
                                                          .toStringAsFixed(1),
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                                if (provider.isVerified)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.verified,
                                                        size: 16,
                                                        color: Colors.green,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Terverifikasi',
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  statusChip,
                                ],
                              )
                            else
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 40,
                                    child: Icon(Icons.person, size: 40),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.businessName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              provider.avgRating
                                                  .toStringAsFixed(1),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (provider.isVerified)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.verified,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Terverifikasi',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 8),
                                        statusChip,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info
                Text(
                  'Informasi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Deskripsi', provider.description ?? '-'),
                _buildInfoRow('Area', provider.area ?? '-'),
                _buildInfoRow('Alamat', provider.address ?? '-'),
                const SizedBox(height: 12),
                if (provider.coverages.isNotEmpty) ...[
                  Text(
                    'Wilayah Layanan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.coverages
                        .where((coverage) => coverage.isActive)
                        .map(
                          (coverage) => Chip(
                            label: Text(
                              coverage.kotaName != null &&
                                      coverage.kotaName!.isNotEmpty
                                  ? '${coverage.kotaName} - ${coverage.kecamatanName}'
                                  : coverage.kecamatanName,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                LocationMapPreview(
                  providerLatitude: provider.latitude,
                  providerLongitude: provider.longitude,
                  providerLabel: provider.businessName,
                ),

                const SizedBox(height: 24),

                // Services
                if (provider.services.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layanan Tersedia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.services.length,
                        itemBuilder: (context, index) {
                          final service = provider.services[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    service.description?.trim().isNotEmpty ==
                                            true
                                        ? service.description!
                                        : 'Deskripsi layanan belum tersedia.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                const SizedBox(height: 16),

                reviewsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, st) => const SizedBox.shrink(),
                  data: (reviewsResponse) {
                    final reviews = reviewsResponse.data;
                    if (reviews.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulasan Pelanggan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          review.customerName ?? 'Pelanggan',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (
                                            starIndex,
                                          ) {
                                            return Icon(
                                              starIndex < review.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 16,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    if ((review.comment ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(review.comment!),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // CTA Button
                if (ref.watch(authControllerProvider).userRole != 'ADMIN')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isBusy) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Provider sedang dipesan pelanggan lain. Anda tetap bisa membuat antrian, tetapi provider mungkin mengarahkan ke penyedia lain.',
                              ),
                            ),
                          );
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateOrderPage(
                              providerId: provider.userId ?? providerId,
                              categoryId: categoryId,
                              services: provider.services,
                              coverages: provider.coverages,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Pesan Sekarang'),
                    ),
                  ),
                if (ref.watch(authControllerProvider).userRole == 'ADMIN')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Akses hanya untuk admin: silakan gunakan menu Admin untuk manajemen dan verifikasi.',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
