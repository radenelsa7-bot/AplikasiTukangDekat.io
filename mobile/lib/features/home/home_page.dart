import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/site_footer.dart';
import '../../shared/widgets/site_header.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../admin/admin_verification_page.dart';
import 'catalog_page.dart';
import 'my_orders_page.dart';

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
            ).colorScheme.onPrimary.withOpacity(0.7),
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
                  Text('Email: ${state.userEmail ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Role: ${state.userRole ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('ID: ${state.userId ?? 'N/A'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
