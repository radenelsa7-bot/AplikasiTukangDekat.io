import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/site_footer.dart';
import '../../shared/widgets/site_header.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../admin/admin_verification_page.dart';
import 'catalog_page.dart';
import 'my_orders_page.dart';
import 'edit_profile_dialog.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final isAdmin = state.userRole == 'ADMIN';
    final tabs = [
      const Tab(icon: Icon(Icons.home), text: 'Beranda'),
      const Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan'),
      if (isAdmin) const Tab(icon: Icon(Icons.verified_user), text: 'Admin'),
      const Tab(icon: Icon(Icons.account_circle), text: 'Akun'),
    ];
    final pages = [
      const CatalogPage(),
      const MyOrdersPage(),
      if (isAdmin) const AdminVerificationPage(),
      _buildAccountTab(context, state),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: TukangDekatHeader(
          title: const Text('TukangDekat'),
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withAlpha((0.7 * 255).round()),
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: TabBarView(children: pages),
        bottomNavigationBar: const TukangDekatFooter(),
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context, dynamic state) {
    final displayName = state.userFullName?.isNotEmpty == true
        ? state.userFullName
        : state.userEmail ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Profil Akun', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        backgroundImage: state.userProfilePhotoPath != null
                            ? NetworkImage(
                                '${Uri.base.origin}/storage/${state.userProfilePhotoPath}',
                              )
                            : null,
                        child: state.userProfilePhotoPath == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.userEmail ?? 'N/A',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (state.userPhoneNumber?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'No HP: ${state.userPhoneNumber}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit Profil',
                        onPressed: () async {
                          final res = await showDialog<bool>(
                            context: context,
                            builder: (_) => const EditProfileDialog(),
                          );
                          if (res == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profil diperbarui')),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Role: ${state.userRole ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('ID: ${state.userId ?? 'N/A'}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Bantuan (Chatbot)'),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/chatbot');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
