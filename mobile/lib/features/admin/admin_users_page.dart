import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';

final adminUsersProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, role) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminUsers(role: role);
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String? _selectedRole;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_selectedRole));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Kelola Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedRole,
                    hint: const Text('Semua Role', style: TextStyle(fontSize: 13)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Role')),
                      DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
                      DropdownMenuItem(value: 'PROVIDER', child: Text('Provider')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => ref.refresh(adminUsersProvider(_selectedRole)), child: const Text('Coba Lagi')),
                ],
              ),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('Tidak ada pengguna'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminUsersProvider(_selectedRole)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, i) => _UserCard(
                    user: users[i],
                    onStatusChanged: () => ref.refresh(adminUsersProvider(_selectedRole)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onStatusChanged;

  const _UserCard({required this.user, required this.onStatusChanged});

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _isLoading = false;

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppTheme.danger;
      case 'PROVIDER': return AppTheme.warning;
      case 'CUSTOMER': return AppTheme.info;
      default: return AppTheme.grey600;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return AppTheme.success;
      case 'SUSPENDED': return AppTheme.danger;
      case 'INACTIVE': return AppTheme.grey600;
      default: return AppTheme.grey400;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'ADMIN': return Icons.admin_panel_settings;
      case 'PROVIDER': return Icons.engineering;
      case 'CUSTOMER': return Icons.person;
      default: return Icons.person_outline;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      
      final userId = widget.user['id'];
      if (userId == null) throw 'User ID tidak ditemukan';
      
      await ref.read(apiServiceProvider).updateUserStatus(
        userId: userId,
        status: newStatus,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diubah ke $newStatus'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Delay refresh callback to avoid widget disposal issues
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onStatusChanged();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final role = u['role'] ?? '';
    final status = u['status'] ?? 'ACTIVE';
    final isAdmin = role == 'ADMIN';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(role).withOpacity(0.1),
              child: Icon(_roleIcon(role), color: _roleColor(role), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(u['email'] ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                  if (u['phone'] != null && u['phone'].toString().isNotEmpty)
                    Text(u['phone'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(role))),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                ),
              ],
            ),
            if (!isAdmin) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                enabled: !_isLoading,
                onSelected: _updateStatus,
                itemBuilder: (_) => [
                  if (status != 'ACTIVE')
                    const PopupMenuItem(value: 'ACTIVE', child: Text('Aktifkan')),
                  if (status != 'SUSPENDED')
                    const PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend')),
                  if (status != 'INACTIVE')
                    const PopupMenuItem(value: 'INACTIVE', child: Text('Nonaktifkan')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
