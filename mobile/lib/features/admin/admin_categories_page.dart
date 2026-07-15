import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/models/category_model.dart';

final adminCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminCategories();
});

class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Kelola Kategori Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => ref.refresh(adminCategoriesProvider), child: const Text('Coba Lagi')),
                ],
              ),
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: AppTheme.grey400.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('Belum ada kategori', style: TextStyle(color: AppTheme.grey600)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminCategoriesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, i) => _CategoryCard(category: categories[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {ServiceCategory? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kategori', hintText: 'contoh: Tukang Listrik'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi', hintText: 'Deskripsi singkat kategori'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  final api = ref.read(apiServiceProvider);
                  if (category == null) {
                    await api.createCategory(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      isActive: isActive,
                    );
                  } else {
                    await api.updateCategory(
                      categoryId: category.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      isActive: isActive,
                    );
                  }
                  ref.refresh(adminCategoriesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger));
                  }
                }
              },
              child: Text(category == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final ServiceCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (category.isActive ? AppTheme.info : AppTheme.grey400).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category_rounded,
                color: category.isActive ? AppTheme.info : AppTheme.grey400,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (category.description.isNotEmpty)
                    Text(category.description, style: const TextStyle(fontSize: 13, color: AppTheme.grey600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (category.isActive ? AppTheme.success : AppTheme.grey400).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: category.isActive ? AppTheme.success : AppTheme.grey600),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  _showEditDialog(context, ref);
                } else if (val == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.danger))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description);
    bool isActive = category.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Kategori'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Kategori')),
                const SizedBox(height: 12),
                TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi')),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await ref.read(apiServiceProvider).updateCategory(
                    categoryId: category.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    isActive: isActive,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ref.refresh(adminCategoriesProvider);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger));
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing dialog while deleting
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text(
                        'Menghapus kategori...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
            if (!isLoading)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () async {
                  setDialogState(() => isLoading = true);
                  try {
                    await ref.read(apiServiceProvider).deleteCategory(category.id);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ref.refresh(adminCategoriesProvider);
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil dihapus'),
                          backgroundColor: AppTheme.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } on Exception catch (e) {
                    setDialogState(() => isLoading = false);
                    if (ctx.mounted) {
                      String errorMessage = _parseErrorMessage(e);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: $errorMessage'),
                          backgroundColor: AppTheme.danger,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Hapus'),
              ),
          ],
        ),
      ),
    );
  }

  String _parseErrorMessage(Exception e) {
    String errorStr = e.toString();

    // Handle rate limiting (429) error
    if (errorStr.contains('429')) {
      return 'Terlalu banyak permintaan. Silakan tunggu beberapa saat sebelum menghapus kategori lain.';
    }

    // Handle conflict (409) error
    if (errorStr.contains('409')) {
      return 'Kategori masih memiliki layanan aktif. Nonaktifkan layanan terlebih dahulu.';
    }

    // Handle not found (404) error
    if (errorStr.contains('404')) {
      return 'Kategori tidak ditemukan.';
    }

    // Handle connection errors
    if (errorStr.contains('Connection') || errorStr.contains('timeout')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    // Default message
    return errorStr.length > 100 ? errorStr.substring(0, 100) + '...' : errorStr;
  }
}
