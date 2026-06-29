import 'package:flutter/material.dart';
import '../features/auth/login_page.dart';

const Color _navy = Color(0xFF0D2B55);
const Color _navyDeep = Color(0xFF081B38);
const Color _orange = Color(0xFFF97316);
const Color _cream = Color(0xFFF5EFE6);
const Color _white = Colors.white;
const Color _border = Color(0xFFE8E0D5);
const Color _textMuted = Color(0xFF7E756E);

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
  bool _showHow = false;
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
      setState(() => _heroVisible = true);
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (!_showServices && offset > 220) {
      setState(() => _showServices = true);
    }
    if (!_showHow && offset > 760) {
      setState(() => _showHow = true);
    }
    if (!_showCta && offset > 1250) {
      setState(() => _showCta = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            AnimatedSection(
              visible: _heroVisible,
              child: _HeroSection(
                floatingController: _floatingController,
                onPrimaryAction: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
            ),
            AnimatedSection(visible: _showServices, child: _ServicesSection()),
            AnimatedSection(visible: _showHow, child: _HowItWorksSection()),
            AnimatedSection(
              visible: _showCta,
              child: _FinalCtaSection(
                onMulaiSekarang: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
            ),
            _TrustBarSection(),
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
  final AnimationController floatingController;
  final VoidCallback onPrimaryAction;

  const _HeroSection({
    required this.floatingController,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDeep, _navy],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _orange.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'Platform jasa lokal modern',
              style: TextStyle(
                color: _orange,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: floatingController,
            builder: (_, child) {
              final offset = (floatingController.value - 0.5).abs() * 10;
              return Transform.translate(
                offset: Offset(0, offset),
                child: child!,
              );
            },
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Center(
                child: Icon(
                  Icons.home_repair_service_rounded,
                  color: _white,
                  size: 78,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Temukan teknisi terpercaya dengan cepat',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: _white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pesan layanan rumah, pantau status order, dan lakukan pembayaran lewat QRIS dari satu aplikasi yang simpel dan modern.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPrimaryAction,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Masuk ke aplikasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceCard(
        icon: Icons.bolt_rounded,
        title: 'Listrik',
        desc: 'Perbaikan, instalasi, dan pemeriksaan cepat.',
      ),
      _ServiceCard(
        icon: Icons.water_drop_rounded,
        title: 'Plumbing',
        desc: 'Pipa bocor, keran, dan perawatan saluran air.',
      ),
      _ServiceCard(
        icon: Icons.ac_unit_rounded,
        title: 'AC',
        desc: 'Service dan pembersihan pendingin ruangan.',
      ),
      _ServiceCard(
        icon: Icons.construction_rounded,
        title: 'Bangunan',
        desc: 'Perbaikan ringan dan pekerjaan rumah kecil.',
      ),
    ];

    return Container(
      color: _cream,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan favorit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pilih kebutuhan Anda dan temukan teknisi dengan cepat.',
            style: TextStyle(color: _textMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (_, index) => services[index],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _orange, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(color: _textMuted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepItem(
        number: '1',
        title: 'Cari kebutuhan',
        desc: 'Pilih layanan yang Anda butuhkan.',
      ),
      _StepItem(
        number: '2',
        title: 'Pilih teknisi',
        desc: 'Bandingkan rating, area, dan harga.',
      ),
      _StepItem(
        number: '3',
        title: 'Pantau order',
        desc: 'DP, pelunasan, dan status semuanya terintegrasi.',
      ),
    ];

    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara kerjanya',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Semua alur dibuat sederhana untuk pengguna dan teknisi.',
            style: TextStyle(color: _textMuted, height: 1.6),
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (e) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: e),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepItem({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w800,
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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: _textMuted, height: 1.4)),
              ],
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(color: _navy),
      child: Column(
        children: [
          Text(
            'Siap memulai?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Masuk ke akun Anda dan rasakan pengalaman pemesanan jasa yang lebih rapi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onMulaiSekarang,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Mulai Sekarang'),
          ),
        ],
      ),
    );
  }
}

class _TrustBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      color: _cream,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: const [
          _TrustChip(label: 'Verified provider'),
          _TrustChip(label: 'Pembayaran aman'),
          _TrustChip(label: 'Notifikasi real-time'),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String label;

  const _TrustChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _navy,
        ),
      ),
    );
  }
}
