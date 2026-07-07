import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_providers.dart';

class AdminVerificationPage extends ConsumerWidget {
  const AdminVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(pendingProvidersProvider);
    final actionState = ref.watch(adminVerificationControllerProvider);

    return Scaffold(
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (providers) {
          if (providers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Tidak ada provider yang menunggu verifikasi.'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isProcessing =
                  actionState.processingProviderId == provider.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            child: Text(
                              (provider.businessName.isNotEmpty
                                      ? provider.businessName[0]
                                      : 'P')
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.businessName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.ownerName ??
                                      'Pemilik tidak diketahui',
                                ),
                                const SizedBox(height: 4),
                                Text('Area: ${provider.area ?? '-'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              provider.isVerified
                                  ? 'Terverifikasi'
                                  : 'Belum diverifikasi',
                            ),
                            backgroundColor: provider.isVerified
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),
                          Chip(
                            label: Text(
                              'Rating ${provider.avgRating.toString()}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      final success = await ref
                                          .read(
                                            adminVerificationControllerProvider
                                                .notifier,
                                          )
                                          .setVerification(
                                            providerId: provider.id,
                                            isVerified: true,
                                          );
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Provider berhasil diverifikasi',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.verified),
                              label: const Text('Verifikasi'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
