import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../features/auth/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    _nameController = TextEditingController(text: authState.userFullName ?? '');
    _phoneController = TextEditingController(text: authState.userPhoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          fullName: fullName.isEmpty ? null : fullName,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        );

    if (!context.mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final errorMessage = ref.read(authControllerProvider).errorMessage ??
        'Gagal memperbarui profil';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phoneController,
                label: 'No. Telepon',
                hintText: 'Masukkan nomor telepon',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  return null;
                },
              ),
              if (authState.userEmail != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email: ${authState.userEmail}',
                    style: TextStyle(
                      color: AppTheme.grey600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.orange,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
