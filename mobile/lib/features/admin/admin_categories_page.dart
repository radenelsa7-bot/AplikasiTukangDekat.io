import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/models/category_model.dart';

final adminCategoriesProvider = FutureProvider<List<ServiceCategory>>((
  ref,
) async {
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
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Row(
            children: [
              Text(
                'Kelola Kategori Layanan',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: Icon(Icons.add, size: 18.sp),
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
                  ElevatedButton(
                    onPressed: () => ref.refresh(adminCategoriesProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64.sp,
                        color: AppTheme.grey400.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 12.h),
                      const Text(
                        'Belum ada kategori',
                        style: TextStyle(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminCategoriesProvider),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: categories.length,
                  itemBuilder: (context, i) =>
                      _CategoryCard(category: categories[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    ServiceCategory? category,
  }) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
          content: SizedBox(
            width: 400.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText: 'contoh: Tukang Listrik',
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Deskripsi singkat kategori',
                  ),
                ),
                SizedBox(height: 12.h),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
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
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (category.isActive ? AppTheme.info : AppTheme.grey400)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.category_rounded,
                color: category.isActive ? AppTheme.info : AppTheme.grey400,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  if (category.description.isNotEmpty)
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.grey600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: (category.isActive ? AppTheme.success : AppTheme.grey400)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                category.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: category.isActive
                      ? AppTheme.success
                      : AppTheme.grey600,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  _showEditDialog(context, ref);
                } else if (val == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18.sp),
                      SizedBox(width: 8.w),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18.sp, color: AppTheme.danger),
                      SizedBox(width: 8.w),
                      const Text(
                        'Hapus',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ],
                  ),
                ),
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await ref
                      .read(apiServiceProvider)
                      .updateCategory(
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).deleteCategory(category.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(adminCategoriesProvider);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
