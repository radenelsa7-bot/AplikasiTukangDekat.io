import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/models/provider_model.dart';

final allProvidersProvider = FutureProvider<List<ProviderProfile>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getAllProviders();
  return response.data;
});

final pendingProvidersProvider = FutureProvider<List<ProviderProfile>>((
  ref,
) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getPendingProviders();
  return response.data;
});

class AdminProvidersPage extends ConsumerStatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  ConsumerState<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends ConsumerState<AdminProvidersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.orange,
            unselectedLabelColor: AppTheme.grey600,
            indicatorColor: AppTheme.orange,
            tabs: const [
              Tab(text: 'Menunggu Verifikasi'),
              Tab(text: 'Semua Provider'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_PendingProvidersList(), _AllProvidersList()],
          ),
        ),
      ],
    );
  }
}

class _PendingProvidersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(pendingProvidersProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(pendingProvidersProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 64,
                  color: AppTheme.success.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Semua provider sudah diverifikasi',
                  style: TextStyle(color: AppTheme.grey600),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(pendingProvidersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, i) => _ProviderCard(
              provider: providers[i],
              showVerifyButton: true,
              onAction: () {
                ref.refresh(pendingProvidersProvider);
                ref.refresh(allProvidersProvider);
              },
            ),
          ),
        );
      },
    );
  }
}

class _AllProvidersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(allProvidersProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(allProvidersProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(child: Text('Belum ada provider'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(allProvidersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, i) => _ProviderCard(
              provider: providers[i],
              showVerifyButton: false,
              onAction: () {
                ref.refresh(pendingProvidersProvider);
                ref.refresh(allProvidersProvider);
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProviderCard extends ConsumerStatefulWidget {
  final ProviderProfile provider;
  final bool showVerifyButton;
  final VoidCallback onAction;

  const _ProviderCard({
    required this.provider,
    required this.showVerifyButton,
    required this.onAction,
  });

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  bool _isLoading = false;

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateProviderVerification(
            providerId: widget.provider.id,
            isVerified: true,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider berhasil diverifikasi'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus() async {
    final isVerified = widget.provider.isVerified;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateProviderVerification(
            providerId: widget.provider.id,
            isVerified: !isVerified,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified
                  ? 'Provider dibatalkan verifikasinya'
                  : 'Provider berhasil diverifikasi',
            ),
            backgroundColor: isVerified ? AppTheme.warning : AppTheme.success,
          ),
        );
      }
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
                  child: Text(
                    (p.businessName.isNotEmpty ? p.businessName[0] : 'P')
                        .toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.businessName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        p.ownerName ?? 'Pemilik tidak diketahui',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(p.isVerified),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.area != null) _buildInfoChip(Icons.location_on, p.area!),
                _buildInfoChip(
                  Icons.star,
                  'Rating: ${p.avgRating.toStringAsFixed(1)}',
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (widget.showVerifyButton)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _verify,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.verified, size: 18.sp),
                      label: const Text('Verifikasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _toggleStatus,
                      icon: Icon(
                        p.isVerified ? Icons.block : Icons.verified,
                        size: 18.sp,
                      ),
                      label: Text(
                        p.isVerified ? 'Batalkan Verifikasi' : 'Verifikasi',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isVerified) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (isVerified ? AppTheme.success : AppTheme.warning).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        isVerified ? 'Terverifikasi' : 'Pending',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isVerified ? AppTheme.success : AppTheme.warning,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppTheme.grey600),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: AppTheme.grey600),
          ),
        ],
      ),
    );
  }
}
