import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Screen yang ditampilkan ketika provider registration menunggu approval
/// Ini adalah blocking screen yang mencegah akses ke dashboard utama
class AwaitingApprovalScreen extends ConsumerWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(
          title: const Text('Verifikasi Akun'),
          elevation: 0,
          automaticallyImplyLeading: false, // Hide back button
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
                      color: AppTheme.info.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      size: 60,
                      color: AppTheme.info,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Menunggu Persetujuan Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Terima kasih telah mendaftar sebagai penyedia layanan di TukangDekat.\n\nAkun Anda sedang ditinjau oleh tim admin kami untuk memastikan kualitas layanan yang terbaik bagi pelanggan.\n\nProses verifikasi biasanya memakan waktu 1-2 hari kerja.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.grey700,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.warning),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Status: Menunggu Persetujuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yang Kami Periksa:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CheckListItem(
                          text: 'Kelengkapan data profil Anda',
                        ),
                        const SizedBox(height: 10),
                        _CheckListItem(
                          text: 'Keaslian dan keabsahan informasi',
                        ),
                        const SizedBox(height: 10),
                        _CheckListItem(
                          text: 'Komitmen terhadap standar layanan kami',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // FAQ / Help Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: AppTheme.info,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Pertanyaan Umum',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Jika ada pertanyaan atau masalah, Anda dapat menghubungi tim support kami melalui:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 16,
                              color: AppTheme.navy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'support@tukangdekat.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppTheme.navy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                '+62-821-XXXX-XXXX',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.info,
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
                        backgroundColor: AppTheme.grey500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Keluar'),
                            content: const Text(
                              'Apakah Anda yakin ingin keluar? Anda dapat login kembali kapan saja.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.danger,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  // Logout
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .logout();
                                  if (context.mounted) {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => false,
                                    );
                                  }
                                },
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
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

                  const SizedBox(height: 16),

                  // Refresh / Check Status Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Refresh provider status
                        final _ = ref.refresh(authControllerProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status sedang diperbarui...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Refresh Status',
                        style: TextStyle(
                          color: AppTheme.navy,
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
      ),
    );
  }
}

/// Check list item untuk FAQ
class _CheckListItem extends StatelessWidget {
  final String text;

  const _CheckListItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            size: 18,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.grey700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
