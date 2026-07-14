
import 'package:flutter/material.dart';
import '../features/auth/login_page.dart';

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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _HeroSection(
              visible: _heroVisible,
              floatingController: _floatingController,
              onPrimaryAction: _navigateToLogin,
            ),
            AnimatedSection(
              visible: _showServices,
              child: _ServicesSection(onAction: _navigateToLogin),
            ),
            AnimatedSection(
              visible: _showHow,
              child: const _HowItWorksSection(),
            ),
            AnimatedSection(
              visible: _showCta,
              child: _CtaSection(onMulaiSekarang: _navigateToLogin),
            ),
            const _TrustBarSection(),
          ],
        ),
      ),
    );
  }
}

class AnimatedSection extends StatelessWidget {
  final Widget child;
  final bool visible;
  const AnimatedSection({
    super.key,
    required this.child,
    required this.visible,
  });

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

class _HeroSection extends StatelessWidget {
  final bool visible;
  final AnimationController floatingController;
  final VoidCallback onPrimaryAction;

  const _HeroSection({
    required this.visible,
    required this.floatingController,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: visible ? 1 : 0,
      child: Container(
        width: double.infinity,
        color: _navy,
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _orange.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Platform Jasa Lokal Terpercaya',
                style: TextStyle(
                  color: _orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'images/logo.jpg',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.build_circle,
                      size: 48,
                      color: _white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  color: _white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                children: [
                  TextSpan(text: 'Solusi Rumah Anda\nAda di '),
                  TextSpan(
                    text: 'TukangDekat',
                    style: TextStyle(color: _orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hubungkan kebutuhan perbaikan rumah Anda dengan teknisi profesional di Kecamatan Bojongloa Kaler secara cepat dan transparan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            const _StatsRow(),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                elevation: 0,
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Mulai Sekarang',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: const [
        _HeroStatChip(label: '50+ Teknisi', icon: Icons.people),
        _HeroStatChip(label: 'Respon Cepat', icon: Icons.flash_on),
        _HeroStatChip(label: 'Terverifikasi', icon: Icons.verified),
      ],
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
        color: _white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white.withValues(alpha: 0.12)),
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

class _ServicesSection extends StatelessWidget {
  final VoidCallback onAction;
  const _ServicesSection({required this.onAction});

  static const _services = [
    _ServiceData(
      icon: Icons.electrical_services,
      title: 'Listrik',
      subtitle: 'Instalasi dan perbaikan listrik rumah.',
    ),
    _ServiceData(
      icon: Icons.plumbing,
      title: 'Plumbing',
      subtitle: 'Atasi kebocoran dan masalah pipa.',
    ),
    _ServiceData(
      icon: Icons.ac_unit,
      title: 'Service AC',
      subtitle: 'Perawatan dan perbaikan AC.',
    ),
    _ServiceData(
      icon: Icons.home_repair_service,
      title: 'Renovasi',
      subtitle: 'Jasa renovasi dan perbaikan rumah.',
    ),
  ];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan Teknisi Profesional',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pasang, perbaiki, dan renovasi dengan teknisi terpercaya dekat lokasi Anda.',
            style: TextStyle(color: _textMuted, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _services.map((service) {
                  return SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 16) / columns,
                    child: _ServiceCategoryCard(data: service, onTap: onAction),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: const [
              _InfoPill(icon: Icons.verified, label: 'Mitra Terverifikasi'),
              _InfoPill(icon: Icons.lock, label: 'Pembayaran Aman'),
              _InfoPill(icon: Icons.schedule, label: 'Respon Cepat'),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _orange, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                  color: _navyDeep.withValues(alpha: 0.06),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

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
            color: _navyDeep.withValues(alpha: 0.05),
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

class _CtaSection extends StatelessWidget {
  final VoidCallback onMulaiSekarang;
  const _CtaSection({required this.onMulaiSekarang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Siap Pesan Jasa Sekarang?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Daftar gratis dan temukan teknisi terbaik di sekitar Anda dalam hitungan menit',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onMulaiSekarang,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mulai Sekarang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onMulaiSekarang,
              style: OutlinedButton.styleFrom(
                foregroundColor: _white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Daftar sebagai Mitra Teknisi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBarSection extends StatelessWidget {
  const _TrustBarSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navyDeep,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Text(
            'TukangDekat',
            style: TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Platform jasa teknisi rumah terpercaya di Kecamatan Bojongloa Kaler.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: const [
              Text(
                'Layanan',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Keunggulan',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Testimoni',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Support Center',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            '\u00a9 2025 TukangDekat. All rights reserved.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
