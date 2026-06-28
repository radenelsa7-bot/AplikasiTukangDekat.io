import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';

const Color _navy = Color(0xFF0D2B55);
const Color _orange = Color(0xFFF97316);
const Color _cream = Color(0xFFF5EFE6);
const Color _white = Colors.white;

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            _ServicesSection(),
            _HowItWorksSection(),
            _CtaSection(
              onMulaiSekarang: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            _TrustBarSection(),
          ],
        ),
      ),
    );
  }
}

// ─── HERO ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Color.fromRGBO(249, 115, 22, 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color.fromRGBO(249, 115, 22, 0.35)),
            ),
            child: const Text(
              '⚡  Platform Jasa Lokal Terpercaya',
              style: TextStyle(
                color: _orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'Logo TukangDekat',
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Text(
                    'TD',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _StatItem(value: '500+', label: 'Mitra Teknisi'),
          _StatDivider(),
          _StatItem(value: '2.4rb', label: 'Pesanan Selesai'),
          _StatDivider(),
          _StatItem(value: '4.9 ★', label: 'Rating Rata-rata'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _orange,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white12);
  }
}

// ─── SERVICES ────────────────────────────────────────────────────────────────

class _ServiceData {
  final String icon, name, desc, tag;
  final bool isOrange;
  const _ServiceData({
    required this.icon,
    required this.name,
    required this.desc,
    required this.tag,
    required this.isOrange,
  });
}

class _ServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const services = [
      _ServiceData(
        icon: '⚡',
        name: 'Instalasi Listrik',
        desc: 'Pemasangan, perbaikan & pengecekan instalasi listrik rumah',
        tag: 'Tersedia 24/7',
        isOrange: true,
      ),
      _ServiceData(
        icon: '🔧',
        name: 'Plumbing & Pipa',
        desc: 'Saluran air, kebocoran pipa, dan instalasi wastafel',
        tag: 'Respon Cepat',
        isOrange: false,
      ),
      _ServiceData(
        icon: '❄️',
        name: 'Service AC',
        desc: 'Cuci, isi freon, perbaikan & instalasi AC baru',
        tag: 'Bergaransi',
        isOrange: true,
      ),
      _ServiceData(
        icon: '🏗️',
        name: 'Bangunan Ringan',
        desc: 'Renovasi, pengecatan, keramik & atap bocor',
        tag: 'Berpengalaman',
        isOrange: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAYANAN KAMI',
            style: TextStyle(
              color: _orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Semua Kebutuhan Rumah',
            style: TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '5 kategori layanan profesional siap membantu Anda',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _ServiceCard(data: services[0])),
                  const SizedBox(width: 12),
                  Expanded(child: _ServiceCard(data: services[1])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ServiceCard(data: services[2])),
                  const SizedBox(width: 12),
                  Expanded(child: _ServiceCard(data: services[3])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ServiceCardWide(
            icon: '📺',
            name: 'Service Elektronik',
            desc:
                'TV, mesin cuci, kulkas, pompa air & perangkat rumah tangga lainnya',
            tag: 'Teknisi Tersertifikasi',
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData data;
  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final iconBg = data.isOrange
        ? const Color(0xFFFFF3EC)
        : const Color(0xFFEEF3FA);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(data.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.name,
            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.desc,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data.tag,
              style: const TextStyle(
                color: _orange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCardWide extends StatelessWidget {
  final String icon, name, desc, tag;
  const _ServiceCardWide({
    required this.icon,
    required this.name,
    required this.desc,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: _orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

// ─── HOW IT WORKS ─────────────────────────────────────────────────────────────

class _StepData {
  final String num, title, desc;
  const _StepData({required this.num, required this.title, required this.desc});
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData(
        num: '1',
        title: 'Pilih Layanan',
        desc:
            'Tentukan kategori jasa yang Anda butuhkan dan isi detail kerusakan',
      ),
      _StepData(
        num: '2',
        title: 'Pilih Teknisi',
        desc:
            'Bandingkan profil, rating, dan harga dari teknisi terdekat di sekitar Anda',
      ),
      _StepData(
        num: '3',
        title: 'Selesai & Bayar',
        desc:
            'Teknisi datang, kerjakan, selesai. Bayar setelah pekerjaan tuntas',
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 24),
      color: _white,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARA KERJA',
            style: TextStyle(
              color: _orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mudah dalam 3 Langkah',
            style: TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pesan layanan tanpa ribet, langsung dari HP Anda',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map(
            (e) => _StepTile(data: e.value, isLast: e.key == steps.length - 1),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final _StepData data;
  final bool isLast;
  const _StepTile({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE8E0D5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _navy,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.num,
                style: const TextStyle(
                  color: _white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.desc,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.5,
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

// ─── CTA ──────────────────────────────────────────────────────────────────────

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
            child: Tooltip(
              message: 'Mulai pendaftaran dan buat pesanan',
              child: ElevatedButton(
                onPressed: onMulaiSekarang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  'Mulai Sekarang',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: 'Daftar sebagai mitra untuk bergabung menjadi teknisi',
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
          ),
        ],
      ),
    );
  }
}

// ─── TRUST BAR ────────────────────────────────────────────────────────────────

class _TrustBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      _TrustItem(icon: '🛡️', label: 'Terpercaya'),
      _TrustItem(icon: '⚡', label: 'Respon Cepat'),
      _TrustItem(icon: '💰', label: 'Transparan'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final String icon;
  final String label;
  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3EC),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20, height: 1)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
