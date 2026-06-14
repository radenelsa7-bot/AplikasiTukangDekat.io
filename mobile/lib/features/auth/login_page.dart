import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'auth_state.dart';
import '../home/home_page.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      final errorMsg =
          ref.read(authControllerProvider).errorMessage ?? 'Login gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F1E8), // Cream background
        child: SafeArea(
          child: isMobile
              ? _buildMobileLayout(state)
              : _buildDesktopLayout(state),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Section
          _buildLogoSection(),
          const SizedBox(height: 48),
          // Form Section
          _buildFormSection(state),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthState state) {
    return Row(
      children: [
        // Left - Form Section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoSection(),
                const SizedBox(height: 60),
                _buildFormSection(state),
              ],
            ),
          ),
        ),
        // Right - Decorative Section
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F3460), // Navy
                  Color(0xFF162D54), // Darker Navy
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDecorativeIllustration(),
                const SizedBox(height: 40),
                const Text(
                  'Teknisi Terpercaya\nUntuk Rumah Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Solusi cepat dan aman untuk\nkebutuhan teknisi rumah Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE8DCC8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(15, 52, 96, 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0F3460),
                  child: const Icon(
                    Icons.build_circle,
                    size: 40,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'TukangDekat',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Layanan Teknisi Terpercaya',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFD4A574),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masuk ke Akun Anda',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silakan login dengan email dan password Anda',
          style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'Masukkan email Anda',
                icon: Icons.email_outlined,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passCtrl,
                label: 'Password',
                hint: 'Masukkan password Anda',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Password wajib diisi';
                  if (value.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF8C42), // Orange
                      Color(0xFFFF7A3D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(255, 140, 66, 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: state.isLoading ? null : _login,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Masuk',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
                  ),
                  GestureDetector(
                    onTap: _goToRegister,
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8C42),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE5E5),
                    border: Border.all(
                      color: Color.fromRGBO(255, 140, 66, 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
            prefixIcon: Icon(icon, color: const Color(0xFFFF8C42), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8DCC8), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8DCC8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF8C42), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.fromRGBO(255, 140, 66, 0.2),
            Color.fromRGBO(15, 52, 96, 0),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.build_circle,
          size: 100,
          color: Color.fromRGBO(255, 140, 66, 0.7),
        ),
      ),
    );
  }
}
