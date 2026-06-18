import 'package:flutter/material.dart';
import '../features/auth/login_page.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 8),
              Column(
                children: [
                  Image.asset('images/logo.jpg', width: 140, height: 140),
                  const SizedBox(height: 16),
                  Text(
                    'TukangDekat',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform Pemesanan Jasa Lokal Terpercaya untuk Warga Kecamatan Bojongloa Kaler. Hubungkan kebutuhan perbaikan rumah Anda dengan teknisi listrik, plumbing, AC, dan bangunan terbaik di sekitar Anda secara transparan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('Mulai Sekarang'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
