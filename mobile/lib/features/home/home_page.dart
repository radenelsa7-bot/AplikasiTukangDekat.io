import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../config/api_config.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../admin/admin_dashboard_page.dart';
import 'catalog_page.dart';
import 'my_orders_page.dart';
import 'edit_profile_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<BottomNavigationBarItem> _bottomItems = [
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

    final pages = [
      const CatalogPage(),
      const MyOrdersPage(),
      _buildAccountTab(context, ref, state),
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _bottomItems,
        selectedItemColor: AppTheme.orange,
        unselectedItemColor: AppTheme.grey600,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context, WidgetRef ref, dynamic state) {
    final displayName = state.userFullName?.isNotEmpty == true
        ? state.userFullName
        : state.userEmail ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
                  color: AppTheme.navy.withOpacity(0.3),
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
                    backgroundImage: state.userProfilePhotoPath != null
                        ? NetworkImage(
                            '${ApiConfig.baseUrl}/api/storage/${state.userProfilePhotoPath}',
                          )
                        : null,
                    onBackgroundImageError: state.userProfilePhotoPath != null
                        ? (_, __) {}
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
                          color: AppTheme.orange.withOpacity(0.2),
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
          color: iconColor.withOpacity(0.1),
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
