import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import 'admin_providers_page.dart';
import 'admin_categories_page.dart';
import 'admin_orders_page.dart';
import 'admin_providers_page.dart';
import 'admin_reports_page.dart';
import 'admin_transactions_page.dart';
import 'admin_users_page.dart';

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminDashboard();
});

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;

  static const List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AdminMenuItem(icon: Icons.engineering_rounded, label: 'Provider'),
    _AdminMenuItem(icon: Icons.category_rounded, label: 'Kategori'),
    _AdminMenuItem(icon: Icons.people_rounded, label: 'Pengguna'),
    _AdminMenuItem(icon: Icons.receipt_long_rounded, label: 'Pesanan'),
    _AdminMenuItem(icon: Icons.payments_rounded, label: 'Transaksi'),
    _AdminMenuItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: _buildAppBar(context),
      backgroundColor: AppTheme.navyLight,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Admin Dashboard'),
      elevation: 0,
      backgroundColor: AppTheme.navy,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
          onPressed: () => _onLogout(context),
        ),
      ],
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildHorizontalNav(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ..._menuItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == i;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedIndex = i),
                splashColor: AppTheme.orange.withValues(alpha: 0.35),
                highlightColor: AppTheme.orange.withValues(alpha: 0.18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.orange.withValues(alpha: 0.15) : null,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? AppTheme.orange : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? AppTheme.orange : Colors.white60,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? AppTheme.orange : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalNav() {
    return Container(
      height: 62,
      color: AppTheme.navyLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _menuItems.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemBuilder: (context, i) {
          final item = _menuItems[i];
          final isSelected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: AppTheme.orange,
              backgroundColor: AppTheme.navy.withOpacity(0.18),
              side: BorderSide.none,
              onSelected: (_) => setState(() => _selectedIndex = i),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardOverview();
      case 1:
        return const AdminProvidersPage();
      case 2:
        return const AdminCategoriesPage();
      case 3:
        return const AdminUsersPage();
      case 4:
        return const AdminOrdersPage();
      case 5:
        return const AdminTransactionsPage();
      case 6:
        return const AdminReportsPage();
      default:
        return const _DashboardOverview();
    }
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String label;
  const _AdminMenuItem({required this.icon, required this.label});
}

class _DashboardOverview extends ConsumerWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text('Gagal memuat dashboard: $err', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(adminDashboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) {
        final stats = Map<String, dynamic>.from(data['stats'] ?? {});
        final recentOrders = List<Map<String, dynamic>>.from(
          (data['recent_orders'] as List?)?.map(
                (e) => Map<String, dynamic>.from(e),
              ) ??
              [],
        );
        final recentPayments = List<Map<String, dynamic>>.from(
          (data['recent_payments'] as List?)?.map(
                (e) => Map<String, dynamic>.from(e),
              ) ??
              [],
        );

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminDashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(stats),
                const SizedBox(height: 28),
                const Text(
                  'Pesanan Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildRecentOrders(recentOrders),
                const SizedBox(height: 28),
                const Text(
                  'Pembayaran Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildRecentPayments(recentPayments),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final items = [
      _StatItem(
        'Total Pengguna',
        '${stats['total_users'] ?? 0}',
        Icons.people,
        AppTheme.info,
      ),
      _StatItem(
        'Customer',
        '${stats['total_customers'] ?? 0}',
        Icons.person,
        AppTheme.success,
      ),
      _StatItem(
        'Provider',
        '${stats['total_providers'] ?? 0}',
        Icons.engineering,
        AppTheme.warning,
      ),
      _StatItem(
        'Menunggu Verifikasi',
        '${stats['pending_providers'] ?? 0}',
        Icons.pending_actions,
        AppTheme.danger,
      ),
      _StatItem(
        'Total Pesanan',
        '${stats['total_orders'] ?? 0}',
        Icons.receipt_long,
        AppTheme.navy,
      ),
      _StatItem(
        'Pesanan Aktif',
        '${stats['active_orders'] ?? 0}',
        Icons.hourglass_top,
        AppTheme.orange,
      ),
      _StatItem(
        'Pesanan Selesai',
        '${stats['completed_orders'] ?? 0}',
        Icons.check_circle,
        AppTheme.success,
      ),
      _StatItem(
        'Total Pendapatan',
        _formatCurrency(stats['total_revenue']),
        Icons.account_balance_wallet,
        AppTheme.info,
      ),
      _StatItem(
        'Total Kategori',
        '${stats['total_categories'] ?? 0}',
        Icons.category,
        AppTheme.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 12, color: item.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppTheme.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentOrders(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada pesanan'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final o = orders[i];
          return ListTile(
            leading: _statusIcon(o['status'] ?? ''),
            title: Text(
              o['order_code'] ?? '#${o['id']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${o['customer_name'] ?? '-'} → ${o['provider_name'] ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(o['status'] ?? ''),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(o['estimated_price']),
                  style: const TextStyle(fontSize: 11, color: AppTheme.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPayments(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada pembayaran'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = payments[i];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payment,
                color: AppTheme.success,
                size: 20,
              ),
            ),
            title: Text(
              'Order #${p['order_id']} - ${p['payment_type'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              p['customer_name'] ?? '-',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              _formatCurrency(p['amount']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _statusIcon(String status) {
    final map = {
      'CREATED': (Icons.fiber_new, AppTheme.info),
      'ACCEPTED': (Icons.thumb_up, AppTheme.warning),
      'IN_PROGRESS': (Icons.construction, AppTheme.orange),
      'COMPLETED': (Icons.check_circle, AppTheme.success),
      'CLOSED': (Icons.lock, AppTheme.grey600),
      'CANCELLED': (Icons.cancel, AppTheme.danger),
    };

    final entry = map[status] ?? (Icons.help, AppTheme.grey400);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: entry.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(entry.$1, color: entry.$2, size: 20),
    );
  }

  static Widget _statusBadge(String status) {
    final colorMap = {
      'CREATED': AppTheme.info,
      'ACCEPTED': AppTheme.warning,
      'IN_PROGRESS': AppTheme.orange,
      'COMPLETED': AppTheme.success,
      'CLOSED': AppTheme.grey600,
      'CANCELLED': AppTheme.danger,
    };

    final color = colorMap[status] ?? AppTheme.grey400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}

