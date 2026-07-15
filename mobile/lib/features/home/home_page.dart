import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../config/api_config.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../auth/provider_approval_guard.dart';
import '../admin/admin_dashboard_page.dart';
import 'catalog_page.dart';
import 'my_orders_page.dart';
import 'provider_services_page.dart';
import 'provider_dashboard_page.dart';
import 'edit_profile_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<BottomNavigationBarItem> _customerBottomItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_rounded),
      label: 'Pesanan',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // Admin gets full dashboard
    if (state.userRole == 'ADMIN') {
      return const AdminDashboardPage();
    }

    final isProvider = state.userRole == 'PROVIDER';
    final bottomItems = _customerBottomItems;
    final pages = isProvider
        ? <Widget>[
            ProviderDashboardPage(
              onOpenOrders: () => setState(() => _selectedIndex = 1),
              onOpenAccount: () => setState(() => _selectedIndex = 2),
            ),
            const MyOrdersPage(),
            _buildAccountTab(context, ref, state),
          ]
        : <Widget>[
            const CatalogPage(),
            const MyOrdersPage(),
            _buildAccountTab(context, ref, state),
          ];

    final scaffold = Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(bottom: false, child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: bottomItems,
        selectedItemColor: AppTheme.orange,
        unselectedItemColor: AppTheme.grey600,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );

    return isProvider
        ? ProviderApprovalGuard(
            providerStatus: state.providerStatus,
            child: scaffold,
          )
        : scaffold;
  }

  Widget _buildAccountTab(BuildContext context, WidgetRef ref, dynamic state) {
    final displayName = state.userFullName?.isNotEmpty == true
        ? state.userFullName
        : state.userEmail ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navy, AppTheme.navyLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.orange, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white12,
                    backgroundImage: state.userProfilePhotoPath != null && state.userProfilePhotoPath!.isNotEmpty
                        ? NetworkImage(
                            '${ApiConfig.baseUrl}/api/storage/${state.userProfilePhotoPath}',
                          )
                        : null,
                    // Fix crash: CircleAvatar mensyaratkan salah satu dari:
                    // - backgroundImage != null
                    // - onBackgroundImageError == null
                    onBackgroundImageError: (state.userProfilePhotoPath != null &&
                            state.userProfilePhotoPath!.isNotEmpty)
                        ? (_, _) {}
                        : null,
                    child: state.userProfilePhotoPath == null
                        ? const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (state.userFullName?.isNotEmpty == true)
                        Text(
                          state.userEmail ?? '',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.userRole ?? 'N/A',
                          style: const TextStyle(
                            color: AppTheme.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.grey200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuTile(
                  icon: Icons.edit_rounded,
                  iconColor: AppTheme.info,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama, foto, dan nomor telepon',
                  onTap: () async {
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (_) => const EditProfileDialog(),
                    );
                    if (!context.mounted) return;
                    if (res == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Profil berhasil diperbarui'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                ),
                if (state.userRole == 'PROVIDER') ...[
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.build_rounded,
                    iconColor: AppTheme.orange,
                    title: 'Kelola Layanan',
                    subtitle: 'Tambah dan edit informasi layanan Anda',
                    onTap: () async {
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderServicesPage(),
                        ),
                      );
                    },
                  ),
                ],
                const Divider(height: 1, indent: 56),
                _buildMenuTile(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: AppTheme.success,
                  title: 'Bantuan (Chatbot)',
                  subtitle: 'Tanya seputar layanan dan pesanan',
                  onTap: () => Navigator.of(context).pushNamed('/chatbot'),
                ),
                if (state.userPhoneNumber?.isNotEmpty == true) ...[
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.phone_rounded,
                    iconColor: AppTheme.warning,
                    title: 'No. Telepon',
                    subtitle: state.userPhoneNumber!,
                    onTap: null,
                  ),
                ],

                const Divider(height: 1, indent: 56),
                _buildMenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.danger,
                  title: 'Logout',
                  subtitle: 'Keluar dari akun',
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppTheme.grey400)
          : null,
      onTap: onTap,
    );
  }
}
