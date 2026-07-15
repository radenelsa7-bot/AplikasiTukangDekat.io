import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/app_text_field.dart';
import 'catalog_providers.dart';
import 'provider_detail_page.dart';

// ─── Category icon mapper ────────────────────────────────────────────────────
IconData _categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('listrik') || n.contains('elektrik')) {
    return Icons.bolt_rounded;
  }
  if (n.contains('plumbing') || n.contains('pipa') || n.contains('air')) {
    return Icons.water_drop_rounded;
  }
  if (n.contains('ac') || n.contains('pendingin')) return Icons.ac_unit_rounded;
  if (n.contains('bangunan') || n.contains('konstruksi')) {
    return Icons.construction_rounded;
  }
  if (n.contains('elektronik') || n.contains('servis')) {
    return Icons.devices_rounded;
  }
  if (n.contains('cat') || n.contains('pengecatan')) {
    return Icons.format_paint_rounded;
  }
  if (n.contains('kebersihan') || n.contains('cleaning')) {
    return Icons.cleaning_services_rounded;
  }
  if (n.contains('taman') || n.contains('landscaping')) {
    return Icons.yard_rounded;
  }
  if (n.contains('atap') || n.contains('genteng')) return Icons.roofing_rounded;
  if (n.contains('keamanan') || n.contains('kunci')) return Icons.lock_rounded;
  if (n.contains('gas')) return Icons.local_fire_department_rounded;
  if (n.contains('pompa')) return Icons.invert_colors_rounded;
  return Icons.home_repair_service_rounded;
}

Color _categoryColor(int index) {
  const colors = [
    Color(0xFFFF6B35), // orange
    Color(0xFF2196F3), // blue
    Color(0xFF00BCD4), // cyan
    Color(0xFF4CAF50), // green
    Color(0xFF9C27B0), // purple
    Color(0xFFE91E63), // pink
    Color(0xFF009688), // teal
    Color(0xFFFF9800), // amber
  ];
  return colors[index % colors.length];
}

// ─── Main Page ───────────────────────────────────────────────────────────────
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  bool _showFooter = false;

  List<Map<String, dynamic>> _kotaList = [];
  List<Map<String, dynamic>> _kecamatanList = [];
  int? _selectedKotaId;
  int? _selectedKecamatanId;
  bool _isLoadingWilayah = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_loadKota);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCatalogData();
    }
  }

  void _refreshCatalogData() {
    final selectedCategory = ref.read(selectedCategoryProvider);
    final searchQuery = ref.read(searchQueryProvider);

    ref.invalidate(categoriesProvider);

    if (searchQuery.isNotEmpty) {
      ref.invalidate(
        searchProvidersProvider(
          ProviderSearchQuery(
            query: searchQuery,
            kotaId: _selectedKotaId,
            kecamatanId: _selectedKecamatanId,
          ),
        ),
      );
    } else if (selectedCategory != null) {
      ref.invalidate(
        providersByCategoryProvider(
          ProviderCatalogQuery(
            categoryId: selectedCategory,
            kotaId: _selectedKotaId,
            kecamatanId: _selectedKecamatanId,
          ),
        ),
      );
    } else {
      final categoriesAsync = ref.read(categoriesProvider);
      categoriesAsync.whenData((categories) {
        if (categories.isNotEmpty) {
          ref.invalidate(
            providersByCategoryProvider(
              ProviderCatalogQuery(
                categoryId: categories.first.id,
                kotaId: _selectedKotaId,
                kecamatanId: _selectedKecamatanId,
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadKota() async {
    setState(() => _isLoadingWilayah = true);
    try {
      final api = ref.read(apiServiceProvider);
      final kota = await api.getKota();
      if (!mounted) return;
      setState(() {
        _kotaList = kota;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat daftar kota'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingWilayah = false);
    }
  }

  Future<void> _loadKecamatan(int kotaId) async {
    final api = ref.read(apiServiceProvider);
    final kecamatan = await api.getKecamatan(kotaId);
    if (!mounted) return;
    setState(() {
      _kecamatanList = kecamatan;
      _selectedKecamatanId = null;
    });
  }

  void _applyLocationFilter() {
    final selectedCategory = ref.read(selectedCategoryProvider);
    final searchQuery = ref.read(searchQueryProvider);

    if (selectedCategory != null) {
      ref.invalidate(
        providersByCategoryProvider(
          ProviderCatalogQuery(
            categoryId: selectedCategory,
            kotaId: _selectedKotaId,
            kecamatanId: _selectedKecamatanId,
          ),
        ),
      );
    }

    if (searchQuery.isNotEmpty) {
      ref.invalidate(
        searchProvidersProvider(
          ProviderSearchQuery(
            query: searchQuery,
            kotaId: _selectedKotaId,
            kecamatanId: _selectedKecamatanId,
          ),
        ),
      );
    }

    if (selectedCategory == null) {
      ref.invalidate(
        providersByLocationProvider(
          ProviderLocationQuery(
            kotaId: _selectedKotaId,
            kecamatanId: _selectedKecamatanId,
          ),
        ),
      );
    }
    setState(() {});
  }

  String? get _activeLocationLabel {
    if (_selectedKotaId == null) return null;
    final kota = _kotaList.where(
      (item) => int.tryParse(item['id']?.toString() ?? '') == _selectedKotaId,
    );
    final kotaName = kota.isEmpty
        ? 'Kota terpilih'
        : kota.first['name']?.toString() ?? 'Kota terpilih';
    if (_selectedKecamatanId == null) return kotaName;
    final kecamatan = _kecamatanList.where(
      (item) =>
          int.tryParse(item['id']?.toString() ?? '') == _selectedKecamatanId,
    );
    final kecamatanName = kecamatan.isEmpty
        ? 'Kecamatan terpilih'
        : kecamatan.first['name']?.toString() ?? 'Kecamatan terpilih';
    return '$kotaName - $kecamatanName';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Show footer when near bottom, hide when scrolling away
        if (notification.metrics.extentAfter < 50 && !_showFooter) {
          setState(() => _showFooter = true);
        } else if (notification.metrics.extentAfter > 100 && _showFooter) {
          setState(() => _showFooter = false);
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(context),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppTextField(
                  controller: _searchCtrl,
                  label: 'Cari teknisi atau layanan',
                  hintText: 'Contoh: listrik, plumbing, AC',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.orange,
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
            ),

            // ── Langkah Mudah ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildLocationFilters(context),
            ),
            _buildSectionHeader(context, 'Langkah Mudah', null),

            // Refactor: GridView agar 3 kartu berjajar rapi horizontal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 136,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return _buildStepCard(
                          context,
                          '1',
                          'Pilih\nLayanan',
                          Icons.category_rounded,
                          const Color(0xFF2196F3),
                        );
                      case 1:
                        return _buildStepCard(
                          context,
                          '2',
                          'Pilih\nProvider',
                          Icons.person_search_rounded,
                          const Color(0xFFFF6B35),
                        );
                      default:
                        return _buildStepCard(
                          context,
                          '3',
                          'Buat\nOrder',
                          Icons.receipt_long_rounded,
                          const Color(0xFF4CAF50),
                        );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 4),
            _buildSectionHeader(context, 'Kategori Layanan', null),
            _buildCategories(context, ref, selectedCategory),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeLocationLabel != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.navy,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Menampilkan teknisi yang melayani $_activeLocationLabel',
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  searchQuery.isNotEmpty
                      ? _buildSearchResults(context, ref)
                      : selectedCategory != null
                      ? _buildProvidersByCategory(
                          context,
                          ref,
                          selectedCategory,
                        )
                      : _buildSuggestedProviders(context, ref),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (_showFooter) const _CatalogFooter(),
            // Beri ruang napas sebelum navigasi bawah agar konten terakhir
            // tidak terasa menempel pada tepi layar.
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Hero Banner ──────────────────────────────────────────────────────────
  Widget _buildLocationFilters(BuildContext context) {
    if (_isLoadingWilayah) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Wilayah',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _selectedKotaId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Kota',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Semua kota'),
              ),
              ..._kotaList.map((item) {
                final id = (item['id'] as num).toInt();
                return DropdownMenuItem<int?>(
                  value: id,
                  child: Text(item['name']?.toString() ?? '-'),
                );
              }),
            ],
            onChanged: (value) async {
              setState(() {
                _selectedKotaId = value;
                _selectedKecamatanId = null;
                _kecamatanList = [];
              });
              if (value != null) {
                await _loadKecamatan(value);
              }
              _applyLocationFilter();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _selectedKecamatanId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Kecamatan',
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Semua kecamatan'),
              ),
              ..._kecamatanList.map((item) {
                final id = (item['id'] as num).toInt();
                return DropdownMenuItem<int?>(
                  value: id,
                  child: Text(item['name']?.toString() ?? '-'),
                );
              }),
            ],
            onChanged: _selectedKotaId == null
                ? null
                : (value) {
                    setState(() => _selectedKecamatanId = value);
                    _applyLocationFilter();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final iconSize = compact ? 48.0 : 64.0;
        final iconInnerSize = compact ? 26.0 : 32.0;
        final padding = EdgeInsets.all(compact ? 18 : 24);
        final titleStyle = compact
            ? Theme.of(context).textTheme.headlineSmall
            : Theme.of(context).textTheme.headlineMedium;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.navy, AppTheme.navyLight],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: compact ? 110 : 140,
                  height: compact ? 110 : 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -30,
                child: Container(
                  width: compact ? 80 : 100,
                  height: compact ? 80 : 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '✦ Teknisi Terpercaya',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white70,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'TukangDekat',
                                  style: titleStyle?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: AppTheme.orange,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.orange.withValues(
                                    alpha: 0.40,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.home_repair_service_rounded,
                              color: Colors.white,
                              size: iconInnerSize,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '✦ Teknisi Terpercaya',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white70,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'TukangDekat',
                                  style: titleStyle?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: AppTheme.orange,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.orange.withValues(
                                    alpha: 0.40,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.home_repair_service_rounded,
                              color: Colors.white,
                              size: iconInnerSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Temukan teknisi terdekat dengan cepat dan aman. Pesan & pantau langsung dari aplikasi.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFeatureChip(
                          Icons.verified_rounded,
                          'Terverifikasi',
                        ),
                        _buildFeatureChip(Icons.payment_rounded, 'Bayar Mudah'),
                        _buildFeatureChip(Icons.shield_rounded, 'Aman'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? action,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (action != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String step,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 14)),
          ),
          const SizedBox(height: 8),
          Text(
            step,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.1,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category.id;
              final color = _categoryColor(index);
              final icon = _categoryIcon(category.name);

              return GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedCategoryProvider.notifier).state = isSelected
                      ? null
                      : category.id;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.grey.withValues(alpha: 0.15),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestedProviders(BuildContext context, WidgetRef ref) {
    if (_selectedKotaId != null || _selectedKecamatanId != null) {
      return _buildProvidersByLocation(context, ref);
    }
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Text('Tidak ada kategori untuk direkomendasikan'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(context, 'Rekomendasi Provider'),
            const SizedBox(height: 12),
            _buildProvidersByCategory(context, ref, categories.first.id),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildProvidersByCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) {
    final providersAsync = ref.watch(
      providersByCategoryProvider(
        ProviderCatalogQuery(
          categoryId: categoryId,
          kotaId: _selectedKotaId,
          kecamatanId: _selectedKecamatanId,
        ),
      ),
    );

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (providers) {
        final activeProviders = providers
            .where((p) => p.userStatus == 'ACTIVE')
            .toList();

        if (activeProviders.isEmpty) {
          return _buildEmptyState(
            context,
            _activeLocationLabel == null
                ? 'Tidak ada provider di kategori ini'
                : 'Tidak ada teknisi yang melayani wilayah ini',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(context, 'Teknisi Tersedia'),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeProviders.length,
              itemBuilder: (context, index) {
                final provider = activeProviders[index];
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
    final resultsAsync = ref.watch(
      searchProvidersProvider(
        ProviderSearchQuery(
          query: searchQuery,
          kotaId: _selectedKotaId,
          kecamatanId: _selectedKecamatanId,
        ),
      ),
    );

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (providers) {
        final activeProviders = providers
            .where((p) => p.userStatus == 'ACTIVE')
            .toList();

        if (activeProviders.isEmpty) {
          return _buildEmptyState(context, 'Tidak ada hasil pencarian');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(
              context,
              'Hasil Pencarian (${activeProviders.length})',
            ),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeProviders.length,
              itemBuilder: (context, index) {
                final provider = activeProviders[index];
                return _buildProviderCard(context, provider, 0);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    dynamic provider,
    int categoryId,
  ) {
    final rating = (provider.avgRating ?? 0.0) as double;
    final isBusy = provider.availabilityStatus == 'BUSY';
    final initials = (provider.businessName as String)
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppTheme.navy, AppTheme.navyLight],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.businessName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      provider.description ??
                                          'Belum ada deskripsi',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Color(0xFFB8860B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isBusy ? Colors.orange : Colors.green)
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isBusy ? 'Sedang dipesan' : 'Tersedia',
                                  style: TextStyle(
                                    color: isBusy
                                        ? Colors.orange
                                        : Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.orange.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppTheme.orange,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.navy, AppTheme.navyLight],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.description ?? 'Belum ada deskripsi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 13,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(0xFFB8860B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isBusy
                                                    ? Colors.orange
                                                    : Colors.green)
                                                .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isBusy ? 'Sedang dipesan' : 'Tersedia',
                                        style: TextStyle(
                                          color: isBusy
                                              ? Colors.orange
                                              : Colors.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppTheme.orange,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProvidersByLocation(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(
      providersByLocationProvider(
        ProviderLocationQuery(
          kotaId: _selectedKotaId,
          kecamatanId: _selectedKecamatanId,
        ),
      ),
    );

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (providers) {
        final activeProviders = providers
            .where((provider) => provider.userStatus == 'ACTIVE')
            .toList();
        if (activeProviders.isEmpty) {
          return _buildEmptyState(
            context,
            'Tidak ada teknisi yang melayani wilayah ini',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(
              context,
              'Teknisi di Wilayah Terpilih (${activeProviders.length})',
            ),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeProviders.length,
              itemBuilder: (context, index) {
                final provider = activeProviders[index];
                final categoryId = provider.services.isNotEmpty
                    ? provider.services.first.categoryId ?? 0
                    : 0;
                return _buildProviderCard(context, provider, categoryId);
              },
            ),
          ],
        );
      },
    );
  }
}

class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'TukangDekat - Temukan teknisi terdekat dengan mudah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.grey600, fontSize: 12),
        ),
      ),
    );
  }
}
