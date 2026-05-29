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
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TukangDekat',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Temukan teknisi terdekat dengan cepat dan aman. Pilih layanan, pesan, dan pantau pengerjaan langsung dari aplikasi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Mulai Cari Sekarang'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.home_repair_service,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: AppTextField(
              controller: _searchCtrl,
              label: 'Cari teknisi atau layanan',
              hintText: 'Contoh: listrik, plumbing, AC',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langkah Mudah',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStepCard(context, '1', 'Pilih layanan'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStepCard(context, '2', 'Pilih provider'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStepCard(context, '3', 'Buat order')),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Kategori Layanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          _buildCategories(context, ref, selectedCategory),
          const SizedBox(height: 32),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchResults(context, ref),
            )
          else if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProvidersByCategory(context, ref, selectedCategory),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, String step, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
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
      error: (err, st) => Center(child: Text('Error: $err')),
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
                        : Theme.of(context).colorScheme.surface,
                    elevation: isSelected ? 5 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_repair_service,
                            size: 40,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
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
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(
            child: Text('Tidak ada provider di kategori ini'),
          );
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
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(child: Text('Tidak ada hasil pencarian'));
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

  Widget _buildProviderCard(
    BuildContext context,
    dynamic provider,
    int categoryId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          provider.businessName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              provider.description ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text('${provider.avgRating ?? 0.0}'),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).colorScheme.primary,
        ),
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
