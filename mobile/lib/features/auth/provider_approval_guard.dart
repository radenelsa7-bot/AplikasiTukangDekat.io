import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/location_models.dart';
import 'awaiting_approval_screen.dart';

/// Middleware/Guard untuk check provider approval status
/// Digunakan di routing untuk redirect ke approval screen jika pending
class ProviderApprovalGuard extends ConsumerWidget {
  final Widget child;
  final String? providerStatus;

  const ProviderApprovalGuard({
    super.key,
    required this.child,
    this.providerStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jika provider_status = 'pending', tampilkan awaiting approval screen
    if (providerStatus == ProviderApprovalStatus.pending.value) {
      return const AwaitingApprovalScreen();
    }

    // Jika provider_status = 'rejected', tampilkan rejected screen
    if (providerStatus == ProviderApprovalStatus.rejected.value) {
      return const RegistrationRejectedScreen();
    }

    // Jika status 'approved' atau tidak ada status (bukan provider), tampilkan child
    return child;
  }
}

/// Screen yang ditampilkan ketika provider registration ditolak
class RegistrationRejectedScreen extends ConsumerWidget {
  const RegistrationRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('Registrasi Ditolak'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Illustration / Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 60,
                    color: Color(0xFFEF4444),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Registrasi Ditolak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A192F),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'Sayangnya, aplikasi registrasi Anda telah ditolak oleh tim admin kami.\n\nUntuk informasi lebih lanjut tentang alasan penolakan, silakan hubungi tim support kami.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 50),

                // Contact Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hubungi Support Kami',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            size: 18,
                            color: Color(0xFF0A192F),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              'support@tukangdekat.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 18,
                            color: Color(0xFF0A192F),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              '+62-821-XXXX-XXXX',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Logout
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
