import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../features/auth/login_page.dart';

// ─── BRAND TOKENS ──────────────────────────────────────────────────────────
// Semua warna diturunkan dari 4 warna brand: navy, orange, cream, putih.

const Color _navy = Color(0xFF0D2B55);
const Color _navyDeep = Color(0xFF081B38);
const Color _navyTint = Color(0xFFE7EBF3);
const Color _orange = Color(0xFFF97316);
const Color _orangeDeep = Color(0xFFEA580C);
const Color _orangeTint = Color(0xFFFFF1E6);
const Color _cream = Color(0xFFF5EFE6);
const Color _white = Colors.white;
const Color _border = Color(0xFFE8E0D5);
const Color _textMuted = Color(0xFF8B8174);
const Color _textOnDark = Color(0xFFD9D3C4);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _floatingController;

  bool _heroVisible = false;
  bool _showServices = false;
  bool _showWhy = false;
  bool _showHow = false;
  bool _showTestimonials = false;
  bool _showCta = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _heroVisible = true;
      });
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (!_showServices && offset > 260) {
      setState(() => _showServices = true);
    }
    if (!_showWhy && offset > 700) {
      setState(() => _showWhy = true);
    }
    if (!_showHow && offset > 1180) {
      setState(() => _showHow = true);
    }
    if (!_showTestimonials && offset > 1700) {
      setState(() => _showTestimonials = true);
    }
    if (!_showCta && offset > 2200) {
      setState(() => _showCta = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PremiumHero(
                visible: _heroVisible,
                floatingController: _floatingController,
                onPrimaryAction: _navigateToLogin,
              ),
              AnimatedSection(
                visible: _showServices,
                child: _SearchAndStatsSection(onAction: _navigateToLogin),
              ),
              AnimatedSection(
                visible: _showWhy,
                child: _ServicesSection(onAction: _navigateToLogin),
              ),
              AnimatedSection(visible: _showHow, child: _WhyChooseSection()),
              AnimatedSection(
                visible: _showTestimonials,
                child: _HowItWorksSection(),
              ),
              AnimatedSection(visible: _showCta, child: _TestimonialsSection()),
              _FinalCtaSection(onMulaiSekarang: _navigateToLogin),
              const _FooterSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedSection extends StatelessWidget {
  final Widget child;
  final bool visible;
  const AnimatedSection({required this.child, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 550),
      opacity: visible ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 550),
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  final bool visible;
  final AnimationController floatingController;
  final VoidCallback onPrimaryAction;
  const _PremiumHero({
    required this.visible,
    required this.floatingController,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyDeep],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 24,
          vertical: isDesktop ? 48 : 28,
        ),
        child: Column(
          children: [
            _HeaderBar(),
            const SizedBox(height: 34),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _HeroTextBlock(
                          onPrimaryAction: onPrimaryAction,
                          visible: visible,
                        ),
                      ),
                      const SizedBox(width: 36),
                      Expanded(
                        child: _HeroVisual(
                          floatingController: floatingController,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _HeroTextBlock(
                        onPrimaryAction: onPrimaryAction,
                        visible: visible,
                      ),
                      const SizedBox(height: 30),
                      _HeroVisual(floatingController: floatingController),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.handyman, color: _orange, size: 18),
              SizedBox(width: 10),
              Text(
                'TukangDekat',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (MediaQuery.of(context).size.width > 980)
          Row(
            children: [
              _HeaderNavItem(label: 'Layanan'),
              _HeaderNavItem(label: 'Keunggulan'),
              _HeaderNavItem(label: 'Cara Kerja'),
              _HeaderNavItem(label: 'Testimoni'),
              const SizedBox(width: 18),
              _SecondaryActionButton(label: 'Masuk', onTap: () {}),
            ],
          )
        else
          _SecondaryActionButton(label: 'Masuk', onTap: () {}),
      ],
    );
  }
}

class _HeaderNavItem extends StatelessWidget {
  final String label;
  const _HeaderNavItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: _white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  final bool visible;
  final VoidCallback onPrimaryAction;
  const _HeroTextBlock({required this.visible, required this.onPrimaryAction});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: visible ? Offset.zero : const Offset(0, 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tukang Terpercaya, Solusi Dekat',
              style: TextStyle(
                color: _orange,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Marketplace Jasa Profesional untuk Rumah & Teknisi Terdekat',
              style: TextStyle(
                color: _white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pesan layanan listrik, AC, plumbing, renovasi, dan teknisi rumah tangga dengan proses yang cepat, aman, dan transparan.',
              style: TextStyle(color: _textOnDark, fontSize: 16, height: 1.7),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PrimaryActionButton(
                  label: 'Mulai Pesan',
                  onTap: onPrimaryAction,
                ),
                const SizedBox(width: 14),
                _SecondaryActionButton(label: 'Lihat Layanan', onTap: () {}),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: _white, size: 20),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Cari layanan: listrik, AC, plumbing, renovasi...',
                      style: TextStyle(color: _white, fontSize: 14),
                    ),
                  ),
                  Text(
                    'Teknisi terdekat',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: const [
                _HeroStatChip(label: '500+ Mitra Teknisi', icon: Icons.people),
                _HeroStatChip(
                  label: '2.4rb Order Selesai',
                  icon: Icons.check_circle,
                ),
                _HeroStatChip(label: 'Rating 4.9/5', icon: Icons.star),
                _HeroStatChip(label: 'Respon < 10 Menit', icon: Icons.timer),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeroStatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _orange, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final AnimationController floatingController;
  const _HeroVisual({required this.floatingController});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _navyDeep.withOpacity(0.95),
                    _navy.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _navyDeep.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            bottom: 24,
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 0,
                  child: _DecorativeCircle(
                    size: 96,
                    color: _orange.withOpacity(0.16),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: _DecorativeCircle(
                    size: 74,
                    color: _white.withOpacity(0.12),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: _HeroCard(
                    color: _white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.home_repair_service, color: _navy, size: 28),
                        SizedBox(height: 14),
                        Text(
                          'Teknisi Rumah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Jasa renovasi, pemasangan, dan perbaikan cepat.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 18,
                  child: _FloatingHeroCard(
                    controller: floatingController,
                    child: _HeroCard(
                      color: _orange,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.bolt, color: _white, size: 28),
                          SizedBox(height: 14),
                          Text(
                            'Service AC',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Respon cepat, solusi sejuk & bersih.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 102,
                  child: _FloatingHeroCard(
                    controller: floatingController,
                    reverse: true,
                    child: _HeroCard(
                      color: _navy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.plumbing, color: _orange, size: 28),
                          SizedBox(height: 14),
                          Text(
                            'Plumbing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Atasi kebocoran dan masalah pipa profesional.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 24,
                  child: _HeroCard(
                    color: _white.withOpacity(0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.timer, color: _white, size: 24),
                        SizedBox(height: 14),
                        Text(
                          'Estimasi Respon 10 Menit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color color;
  final Widget child;
  const _HeroCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navyDeep.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingHeroCard extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  final bool reverse;
  const _FloatingHeroCard({
    required this.controller,
    required this.child,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, widget) {
        final progress = controller.value;
        final dy =
            math.sin(progress * math.pi * 2 + (reverse ? math.pi : 0)) * 8;
        return Transform.translate(offset: Offset(0, dy), child: widget);
      },
      child: child,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        backgroundColor: _orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: 1,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: BorderSide(color: _white.withOpacity(0.24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

class _SearchAndStatsSection extends StatelessWidget {
  final VoidCallback onAction;
  const _SearchAndStatsSection({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Temukan Teknisi Profesional dengan Cepat',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pasang, perbaiki, dan renovasi dengan teknisi terpercaya dekat lokasi Anda. Semua layanan tersedia dalam satu platform.',
            style: TextStyle(color: _textMuted, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _navyDeep.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Cari layanan, mis. Service AC atau listrik',
                          hintStyle: TextStyle(
                            color: _textMuted.withOpacity(0.9),
                          ),
                          prefixIcon: const Icon(Icons.search, color: _navy),
                          filled: true,
                          fillColor: _cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                      ),
                      child: const Text(
                        'Telusuri',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: const [
                    _InfoPill(
                      icon: Icons.verified,
                      label: 'Mitra Terverifikasi',
                    ),
                    _InfoPill(icon: Icons.lock, label: 'Pembayaran Aman'),
                    _InfoPill(icon: Icons.schedule, label: 'Respon Cepat'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navyDeep.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _navy, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final VoidCallback onAction;
  const _ServicesSection({required this.onAction});

  static const services = [
    _ServiceData(
      icon: Icons.bolt,
      title: 'Tukang Listrik',
      subtitle: 'Perbaikan, instalasi, dan pengecekan profesional',
    ),
    _ServiceData(
      icon: Icons.ac_unit,
      title: 'Service AC',
      subtitle: 'Cuci, isi freon, dan perbaikan cepat',
    ),
    _ServiceData(
      icon: Icons.plumbing,
      title: 'Plumbing',
      subtitle: 'Saluran air, kebocoran, dan wastafel',
    ),
    _ServiceData(
      icon: Icons.home_repair_service,
      title: 'Renovasi Rumah',
      subtitle: 'Pengecatan, perbaikan, dan finishing',
    ),
    _ServiceData(
      icon: Icons.tv,
      title: 'Service Elektronik',
      subtitle: 'TV, kulkas, mesin cuci, dan perangkat rumah',
    ),
    _ServiceData(
      icon: Icons.handyman,
      title: 'Teknisi Rumah Tangga',
      subtitle: 'Jasa rumah tangga lengkap dalam satu platform',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth > 1000
        ? 3
        : screenWidth > 700
        ? 2
        : 1;
    return Container(
      color: _cream,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 900 ? 60 : 24,
          vertical: 36,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Layanan',
              style: TextStyle(
                color: _navy,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Akses semua layanan tukang dan teknisi terpercaya di sekitar Anda.',
              style: TextStyle(color: _textMuted, fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                return _ServiceCategoryCard(
                  data: services[index],
                  onTap: onAction,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ServiceData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ServiceCategoryCard extends StatefulWidget {
  final _ServiceData data;
  final VoidCallback onTap;
  const _ServiceCategoryCard({required this.data, required this.onTap});

  @override
  State<_ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<_ServiceCategoryCard> {
  bool _hover = false;
  bool _pressed = false;

  void _update(bool hover) {
    setState(() {
      _hover = hover;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hover ? 1.02 : 1.0);
    return MouseRegion(
      onEnter: (_) => _update(true),
      onExit: (_) => _update(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _navyDeep.withOpacity(0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _orangeTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.data.icon, color: _orange, size: 26),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.data.subtitle,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                Row(
                  children: const [
                    Text(
                      'Selengkapnya',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, color: _orange, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyChooseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 900 ? 60 : 24,
        vertical: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mengapa Pilih TukangDekat?',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Platform modern yang membantu Anda menemukan jasa profesional, aman, dan dapat diandalkan.',
            style: TextStyle(color: _textMuted, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: const [
              _FeatureCard(
                icon: Icons.shield,
                title: 'Aman & Terpercaya',
                description:
                    'Verifikasi teknisi lengkap dengan reputasi dan ulasan nyata.',
              ),
              _FeatureCard(
                icon: Icons.flash_on,
                title: 'Cepat & Responsif',
                description:
                    'Permintaan ditangani dalam hitungan menit oleh teknisi terdekat.',
              ),
              _FeatureCard(
                icon: Icons.analytics,
                title: 'Transparan',
                description:
                    'Estimasi harga dan progress pekerjaan terlihat jelas.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navyDeep.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _orangeTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: _orange, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  static const steps = [
    _StepData(
      number: '1',
      title: 'Pilih Layanan',
      description:
          'Pilih kategori jasa dan jelaskan kebutuhan Anda secara singkat.',
    ),
    _StepData(
      number: '2',
      title: 'Pilih Teknisi',
      description: 'Lihat profil, rating, dan estimasi biaya sebelum memesan.',
    ),
    _StepData(
      number: '3',
      title: 'Selesai & Bayar',
      description: 'Teknisi datang, kerja selesai, bayar setelah puas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    return Container(
      color: _navyDeep,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 24,
          vertical: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cara Kerja TukangDekat',
              style: TextStyle(
                color: _white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dari pencarian sampai pembayaran, semua dibuat sederhana dan profesional.',
              style: TextStyle(color: _textOnDark, fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 32),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps
                        .map((step) => Expanded(child: _StepTile(data: step)))
                        .toList(),
                  )
                : Column(
                    children: steps
                        .map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _StepTile(data: step),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final String number;
  final String title;
  final String description;
  const _StepData({
    required this.number,
    required this.title,
    required this.description,
  });
}

class _StepTile extends StatelessWidget {
  final _StepData data;
  const _StepTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navyDeep.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _orangeTint,
            child: Text(
              data.number,
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  static const testimonials = [
    _TestimonialData(
      name: 'Ayu W.',
      note:
          'Teknisi datang cepat dan servisenya sangat rapi. Saya merasa aman dan puas.',
      rating: 5,
    ),
    _TestimonialData(
      name: 'Rudi H.',
      note:
          'Proses pemesanan mudah sekali. Teknisi jelas profesional dan harga transparan.',
      rating: 5,
    ),
    _TestimonialData(
      name: 'Nina S.',
      note:
          'Sangat membantu! Renovasi kecil selesai tepat waktu dengan hasil rapi.',
      rating: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 900 ? 60 : 24,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Testimoni Pelanggan',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ulasan nyata dari pelanggan yang sudah merasakan layanan terpercaya dan profesional.',
            style: TextStyle(color: _textMuted, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1000
                  ? 3
                  : constraints.maxWidth > 700
                  ? 2
                  : 1;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: testimonials.map((testimonial) {
                  return SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 20) / columns,
                    child: _TestimonialCard(data: testimonial),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TestimonialData {
  final String name;
  final String note;
  final int rating;
  const _TestimonialData({
    required this.name,
    required this.note,
    required this.rating,
  });
}

class _TestimonialCard extends StatelessWidget {
  final _TestimonialData data;
  const _TestimonialCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navyDeep.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              data.rating,
              (index) => const Icon(Icons.star, color: _orange, size: 18),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.note,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.name,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _navy),
          ),
        ],
      ),
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  final VoidCallback onMulaiSekarang;
  const _FinalCtaSection({required this.onMulaiSekarang});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: screenWidth > 900 ? 60 : 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [_navy, _navyDeep]),
          boxShadow: [
            BoxShadow(
              color: _navyDeep.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Siap Mencari Teknisi Terbaik di Sekitar Anda?',
              style: TextStyle(
                color: _white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mulai sekarang dan nikmati layanan profesional dengan pengalaman pemesanan yang mulus.',
              style: TextStyle(color: _textOnDark, fontSize: 16, height: 1.75),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                _PrimaryActionButton(
                  label: 'Mulai Sekarang',
                  onTap: onMulaiSekarang,
                ),
                const SizedBox(width: 16),
                _SecondaryActionButton(label: 'Jelajahi Layanan', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    return Container(
      color: _navyDeep,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: _FooterBrand()),
                    SizedBox(width: 40),
                    Expanded(child: _FooterLinks()),
                    SizedBox(width: 40),
                    Expanded(child: _FooterSupport()),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterBrand(),
                    SizedBox(height: 24),
                    _FooterLinks(),
                    SizedBox(height: 24),
                    _FooterSupport(),
                  ],
                ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white24),
          const SizedBox(height: 18),
          const Text(
            '© 2026 TukangDekat. Semua hak dilindungi.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'TukangDekat',
          style: TextStyle(
            color: _white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Marketplace jasa tukang dan teknisi yang membantu Anda menemukan layanan profesional dengan cepat dan aman.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.75),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Tautan',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14),
        Text('Layanan', style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 8),
        Text(
          'Keunggulan',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          'Testimoni',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class _FooterSupport extends StatelessWidget {
  const _FooterSupport();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bantuan',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Support Center',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          'Cara Kerja',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          'Syarat & Ketentuan',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
