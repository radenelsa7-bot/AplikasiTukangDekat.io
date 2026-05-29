import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_text_field.dart';
import 'catalog_providers.dart';
import 'provider_detail_page.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            AppTextField(
              controller: _searchCtrl,
              label: 'Cari teknisi atau layanan',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 24),

            // Search results
            if (searchQuery.isNotEmpty)
              _buildSearchResults(context, ref)
            else ...[
              // Categories
              Text(
                'Kategori Layanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildCategories(context, ref, selectedCategory),
              const SizedBox(height: 32),

              // Providers by category
              if (selectedCategory != null)
                _buildProvidersByCategory(context, ref, selectedCategory),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(
    BuildContext context,
    WidgetRef ref,
    int? selectedCategory,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Tidak ada kategori'));
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category.id;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        isSelected ? null : category.id;
                  },
                  child: Card(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_repair_service,
                            size: 40,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProvidersByCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) {
    final providersAsync = ref.watch(providersByCategoryProvider(categoryId));

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(child: Text('Tidak ada provider di kategori ini'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teknisi Tersedia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _buildProviderCard(context, provider, categoryId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchProvidersProvider(searchQuery));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(
            child: Text('Tidak ada hasil pencarian'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Pencarian (${providers.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _buildProviderCard(context, provider, 0);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProviderCard(BuildContext context, dynamic provider, int categoryId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(provider.businessName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(provider.description ?? 'No description',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${provider.avgRating ?? 0.0}'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderDetailPage(
                providerId: provider.id,
                categoryId: categoryId,
              ),
            ),
          );
        },
      ),
    );
  }
}
