import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_model.dart';
import '../../core/services/api_service.dart';
import 'auth_controller.dart';
import 'auth_state.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  String _selectedRole = 'CUSTOMER';
  int? _selectedCategoryId;
  List<ServiceCategory> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = response.data;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _businessNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_passCtrl.text != _passConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password tidak cocok'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
          role: _selectedRole,
          categoryId: _selectedRole == 'PROVIDER' ? _selectedCategoryId : null,
          businessName: _selectedRole == 'PROVIDER'
              ? _businessNameCtrl.text.trim()
              : null,
        );

    if (!mounted) return;

    if (success) {
      final message = _selectedRole == 'PROVIDER'
          ? 'Registrasi berhasil! Akun Anda menunggu verifikasi admin sebelum dapat melayani pesanan.'
          : 'Registrasi berhasil! Silakan login';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      final errorMsg =
          ref.read(authControllerProvider).errorMessage ?? 'Registrasi gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
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
          _buildLogoSection(),
          const SizedBox(height: 40),
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
                const SizedBox(height: 40),
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
                  'Bergabunglah dengan Kami',
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
                  'Dapatkan akses ke ribuan teknisi\nterpercaya dan berkualitas',
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
          'Buat Akun Baru',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Daftar sebagai pelanggan atau teknisi',
          style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameCtrl,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama Anda',
                icon: Icons.person_outline,
                errorText: state.fieldErrors['name'],
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Nama wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'Masukkan email Anda',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: state.fieldErrors['email'],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Nomor HP',
                hint: 'Masukkan nomor HP Anda',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: state.fieldErrors['phone'],
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Nomor HP wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildRoleDropdown(errorText: state.fieldErrors['role']),
              if (_selectedRole == 'PROVIDER') ...[
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _businessNameCtrl,
                  label: 'Nama Usaha',
                  hint: 'Contoh: Jasa Listrik Pak Budi',
                  icon: Icons.store_outlined,
                  errorText: state.fieldErrors['business_name'],
                  validator: (v) {
                    if (_selectedRole == 'PROVIDER' &&
                        (v ?? '').trim().isEmpty) {
                      return 'Nama usaha wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildCategoryDropdown(
                  errorText: state.fieldErrors['category_id'],
                ),
              ],
              const SizedBox(height: 14),
              _buildTextField(
                controller: _passCtrl,
                label: 'Password',
                hint: 'Minimal 8 karakter, gunakan huruf kapital, angka, dan simbol',
                icon: Icons.lock_outline,
                obscureText: true,
                errorText: state.fieldErrors['password'],
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Password wajib diisi';
                  if (value.length < 8) return 'Password minimal 8 karakter';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password harus mengandung huruf kapital';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Password harus mengandung angka';
                  }
                  if (!RegExp(r'[@\$!%*?&]').hasMatch(value)) {
                    return 'Password harus mengandung simbol (@\$!%*?&)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _passConfirmCtrl,
                label: 'Konfirmasi Password',
                hint: 'Ulangi password Anda',
                icon: Icons.lock_outline,
                obscureText: true,
                errorText: state.fieldErrors['password_confirmation'],
                validator: (v) {
                  if ((v ?? '').isEmpty) {
                    return 'Konfirmasi password wajib diisi';
                  }
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
                    onTap: state.isLoading ? null : _register,
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
                              'Daftar',
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
                    'Sudah punya akun? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Masuk di Sini',
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? errorText,
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
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
            prefixIcon: Icon(icon, color: const Color(0xFFFF8C42), size: 20),
            filled: true,
            fillColor: Colors.white,
            errorText: errorText,
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

  Widget _buildRoleDropdown({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Akun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8DCC8), width: 1),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.account_box_outlined,
                color: Color(0xFFFF8C42),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              errorText: errorText,
            ),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'CUSTOMER', child: Text('Pelanggan')),
              DropdownMenuItem(value: 'PROVIDER', child: Text('Teknisi')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Layanan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8DCC8), width: 1),
          ),
          child: _loadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      color: Color(0xFFFF8C42),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    errorText: errorText,
                  ),
                  isExpanded: true,
                  hint: const Text('Pilih kategori layanan'),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                  validator: (v) {
                    if (_selectedRole == 'PROVIDER' && v == null) {
                      return 'Kategori layanan wajib dipilih';
                    }
                    return null;
                  },
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
          Icons.group_add,
          size: 100,
          color: Color.fromRGBO(255, 140, 66, 0.7),
        ),
      ),
    );
  }
}
